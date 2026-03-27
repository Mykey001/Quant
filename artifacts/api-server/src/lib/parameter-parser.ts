export interface StrategyParameter {
  name: string;
  label: string;
  value: string;
  type: "int" | "double" | "bool" | "string" | "color" | "enum";
  description: string;
  options?: string[] | null;
  min?: number | null;
  max?: number | null;
}

// ─── MQ5 / MQL4 ────────────────────────────────────────────────────────────
// Matches: input int    StopLoss = 50;      // Stop loss in pips
//          extern double RiskPercent = 1.5;
const MQ5_PARAM_RE =
  /^[ \t]*(?:input|extern)\s+(?:static\s+)?(\w+)\s+(\w+)\s*=\s*([^;]+);[ \t]*(?:\/\/[ \t]*(.*))?$/gm;

function parseMq5(content: string): StrategyParameter[] {
  const params: StrategyParameter[] = [];
  let m: RegExpExecArray | null;
  MQ5_PARAM_RE.lastIndex = 0;

  while ((m = MQ5_PARAM_RE.exec(content)) !== null) {
    const [, rawType, name, rawValue, comment] = m;
    const value = rawValue.trim();
    const type = mapMq5Type(rawType);
    params.push({
      name,
      label: camelToLabel(name),
      value,
      type,
      description: comment?.trim() ?? "",
      options: type === "enum" ? extractEnumOptions(content, name) : null,
      min: null,
      max: null,
    });
  }
  return params;
}

function mapMq5Type(raw: string): StrategyParameter["type"] {
  const t = raw.toLowerCase();
  if (t === "int" || t === "uint" || t === "long" || t === "ulong") return "int";
  if (t === "double" || t === "float") return "double";
  if (t === "bool") return "bool";
  if (t === "color") return "color";
  if (t === "string") return "string";
  return "string";
}

function extractEnumOptions(content: string, name: string): string[] | null {
  // Look for an ENUM_VALUES or similar pattern nearby the variable
  const re = new RegExp(`enum\\s+\\w+\\s*\\{([^}]+)\\}`, "g");
  let m: RegExpExecArray | null;
  const allEnums: string[][] = [];
  while ((m = re.exec(content)) !== null) {
    allEnums.push(m[1].split(",").map(s => s.trim().split(/\s+/)[0]).filter(Boolean));
  }
  if (allEnums.length > 0) return allEnums[0];
  return null;
}

// ─── PineScript ──────────────────────────────────────────────────────────────
// Matches various input() call patterns:
//   length = input(14, title="Length")
//   rsiLength = input.int(14, "RSI Length", minval=1, maxval=200)
//   showSignals = input.bool(true, "Show Signals")
//   src = input.source(close, "Source")
const PINE_INPUT_RE =
  /^[ \t]*(\w+)\s*=\s*input(?:\.(\w+))?\s*\(([^)]+)\)/gm;

function parsePine(content: string): StrategyParameter[] {
  const params: StrategyParameter[] = [];
  let m: RegExpExecArray | null;
  PINE_INPUT_RE.lastIndex = 0;

  while ((m = PINE_INPUT_RE.exec(content)) !== null) {
    const [, name, subtype, argsRaw] = m;
    const args = parseArgs(argsRaw);
    const defaultVal = args[0] ?? "";
    const title = extractNamedArg(argsRaw, "title") ?? args[1] ?? camelToLabel(name);
    const minval = extractNamedArg(argsRaw, "minval");
    const maxval = extractNamedArg(argsRaw, "maxval");
    const options = extractPineOptions(argsRaw);

    params.push({
      name,
      label: title.replace(/^["']|["']$/g, ""),
      value: defaultVal.replace(/^["']|["']$/g, ""),
      type: mapPineType(subtype, defaultVal),
      description: "",
      options: options ?? null,
      min: minval !== undefined ? parseFloat(minval) : null,
      max: maxval !== undefined ? parseFloat(maxval) : null,
    });
  }
  return params;
}

function mapPineType(sub: string | undefined, value: string): StrategyParameter["type"] {
  if (!sub) {
    if (value === "true" || value === "false") return "bool";
    if (!isNaN(parseFloat(value))) return "double";
    return "string";
  }
  switch (sub) {
    case "int": return "int";
    case "float": return "double";
    case "bool": return "bool";
    case "color": return "color";
    case "string": return "string";
    case "source": return "enum";
    default: return "string";
  }
}

function parseArgs(raw: string): string[] {
  const result: string[] = [];
  let depth = 0;
  let current = "";
  let inStr = false;
  let strChar = "";
  for (const ch of raw) {
    if (inStr) {
      current += ch;
      if (ch === strChar) inStr = false;
    } else if (ch === '"' || ch === "'") {
      inStr = true;
      strChar = ch;
      current += ch;
    } else if (ch === "(" || ch === "[") {
      depth++;
      current += ch;
    } else if (ch === ")" || ch === "]") {
      depth--;
      current += ch;
    } else if (ch === "," && depth === 0) {
      result.push(current.trim());
      current = "";
    } else {
      current += ch;
    }
  }
  if (current.trim()) result.push(current.trim());
  return result;
}

function extractNamedArg(raw: string, key: string): string | undefined {
  const re = new RegExp(`\\b${key}\\s*=\\s*([^,)]+)`, "i");
  const m = re.exec(raw);
  return m ? m[1].trim() : undefined;
}

function extractPineOptions(raw: string): string[] | null {
  const m = /options\s*=\s*\[([^\]]+)\]/.exec(raw);
  if (!m) return null;
  return m[1].split(",").map(s => s.trim().replace(/^["']|["']$/g, ""));
}

// ─── Python ──────────────────────────────────────────────────────────────────
// Matches top-level UPPER_CASE constants, or annotated params with # param
const PY_CONST_RE =
  /^[ \t]*([A-Z][A-Z0-9_]{1,})\s*(?::\s*\w+)?\s*=\s*([^\n#]+?)[ \t]*(?:#[ \t]*(.*))?$/gm;
// Also matches lowercase assignments if they have a # param comment
const PY_PARAM_RE =
  /^[ \t]*(\w+)\s*(?::\s*\w+)?\s*=\s*([^\n#]+?)[ \t]*#[ \t]*(param:?\s*.+)$/gm;

function parsePython(content: string): StrategyParameter[] {
  const params: StrategyParameter[] = [];
  const seen = new Set<string>();

  const addParam = (name: string, rawVal: string, comment: string) => {
    if (seen.has(name)) return;
    seen.add(name);
    const value = rawVal.trim();
    const type = inferPythonType(value);
    params.push({
      name,
      label: snakeToLabel(name),
      value: value.replace(/^["']|["']$/g, ""),
      type,
      description: comment?.replace(/^param:?\s*/i, "").trim() ?? "",
      options: null,
      min: null,
      max: null,
    });
  };

  let m: RegExpExecArray | null;
  PY_CONST_RE.lastIndex = 0;
  while ((m = PY_CONST_RE.exec(content)) !== null) {
    addParam(m[1], m[2], m[3] ?? "");
  }
  PY_PARAM_RE.lastIndex = 0;
  while ((m = PY_PARAM_RE.exec(content)) !== null) {
    addParam(m[1], m[2], m[3] ?? "");
  }
  return params;
}

function inferPythonType(value: string): StrategyParameter["type"] {
  if (value === "True" || value === "False") return "bool";
  if (/^\d+$/.test(value)) return "int";
  if (/^\d*\.\d+$/.test(value)) return "double";
  return "string";
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function camelToLabel(name: string): string {
  return name
    .replace(/([A-Z])/g, " $1")
    .replace(/_/g, " ")
    .trim()
    .replace(/\b\w/g, c => c.toUpperCase());
}

function snakeToLabel(name: string): string {
  return name
    .replace(/_/g, " ")
    .replace(/\b\w/g, c => c.toUpperCase());
}

// ─── Apply updated parameter values back into file content ───────────────────
export function applyParametersToContent(
  content: string,
  fileType: string,
  params: StrategyParameter[]
): string {
  let updated = content;
  for (const param of params) {
    if (fileType === "mq5" || fileType === "mql4") {
      // Replace: input <type> <name> = <old_value>;
      const re = new RegExp(
        `((?:input|extern)\\s+(?:static\\s+)?\\w+\\s+${escapeRe(param.name)}\\s*=\\s*)([^;]+)(;)`,
        "g"
      );
      updated = updated.replace(re, `$1${param.value}$3`);
    } else if (fileType === "pine") {
      // Replace: name = input(...default...,  by replacing the first positional arg
      const re = new RegExp(
        `(\\b${escapeRe(param.name)}\\s*=\\s*input(?:\\.\\w+)?\\s*\\()([^,)]+)`,
        "g"
      );
      updated = updated.replace(re, `$1${param.value}`);
    } else if (fileType === "python" || fileType === "other") {
      // Replace: NAME = <old>
      const re = new RegExp(
        `(^[ \\t]*${escapeRe(param.name)}\\s*(?::\\s*\\w+)?\\s*=\\s*)([^\\n#]+)`,
        "gm"
      );
      updated = updated.replace(re, `$1${param.value}`);
    }
  }
  return updated;
}

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// ─── Main dispatch ────────────────────────────────────────────────────────────
export function parseParameters(content: string, fileType: string): StrategyParameter[] {
  switch (fileType) {
    case "mq5":
    case "mql4":
      return parseMq5(content);
    case "pine":
      return parsePine(content);
    case "python":
      return parsePython(content);
    default:
      // Try MQ5 first, then Pine, then Python for generic/unknown files
      const mq5 = parseMq5(content);
      if (mq5.length > 0) return mq5;
      const pine = parsePine(content);
      if (pine.length > 0) return pine;
      return parsePython(content);
  }
}
