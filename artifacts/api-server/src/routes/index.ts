import { Router, type IRouter } from "express";
import healthRouter from "./health";
import strategiesRouter from "./strategies";
import runsRouter from "./runs";
import datasetsRouter from "./datasets";

const router: IRouter = Router();

router.use(healthRouter);
router.use(strategiesRouter);
router.use(runsRouter);
router.use("/datasets", datasetsRouter);

export default router;
