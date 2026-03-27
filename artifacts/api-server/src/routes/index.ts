import { Router, type IRouter } from "express";
import healthRouter from "./health";
import strategiesRouter from "./strategies";
import runsRouter from "./runs";

const router: IRouter = Router();

router.use(healthRouter);
router.use(strategiesRouter);
router.use(runsRouter);

export default router;
