from EventManager.Models.RunnerEvents import RunnerEvents
from EventManager.EventSubscriptionController import EventSubscriptionController
from ConfigValidator.Config.Models.RunTableModel import RunTableModel
from ConfigValidator.Config.Models.FactorModel import FactorModel
from ConfigValidator.Config.Models.RunnerContext import RunnerContext
from ConfigValidator.Config.Models.OperationType import OperationType
from ProgressManager.Output.OutputProcedure import OutputProcedure as output
from Plugins.Profilers.EnergiBridge import EnergiBridge

import sys
from typing import Dict, List, Any, Optional
from pathlib import Path
from os.path import dirname, realpath
import os

class RunnerConfig:
    ROOT_DIR = Path(dirname(realpath(__file__)))

    # ================================ USER SPECIFIC CONFIG ================================
    """The name of the experiment."""
    name:                       str             = "new_runner_experiment"

    """The path in which Experiment Runner will create a folder with the name `self.name`, in order to store the
    results from this experiment. (Path does not need to exist - it will be created if necessary.)
    Output path defaults to the config file's path, inside the folder 'experiments'"""
    results_output_path:        Path             = ROOT_DIR / 'experiments'

    """Experiment operation type. Unless you manually want to initiate each run, use `OperationType.AUTO`."""
    operation_type:             OperationType   = OperationType.AUTO

    """The time Experiment Runner will wait after a run completes.
    This can be essential to accommodate for cooldown periods on some systems."""
    time_between_runs_in_ms:    int             = 60000

    # Dynamic configurations can be one-time satisfied here before the program takes the config as-is
    # e.g. Setting some variable based on some criteria
    def __init__(self):
        """Executes immediately after program start, on config load"""

        EventSubscriptionController.subscribe_to_multiple_events([
            (RunnerEvents.BEFORE_EXPERIMENT, self.before_experiment),
            (RunnerEvents.BEFORE_RUN       , self.before_run       ),
            (RunnerEvents.START_RUN        , self.start_run        ),
            (RunnerEvents.START_MEASUREMENT, self.start_measurement),
            (RunnerEvents.INTERACT         , self.interact         ),
            (RunnerEvents.STOP_MEASUREMENT , self.stop_measurement ),
            (RunnerEvents.STOP_RUN         , self.stop_run         ),
            (RunnerEvents.POPULATE_RUN_DATA, self.populate_run_data),
            (RunnerEvents.AFTER_EXPERIMENT , self.after_experiment )
        ])
        self.run_table_model = None  # Initialized later

        output.console_log("Custom config loaded")

    def create_run_table_model(self) -> RunTableModel:
        """Create and return the run_table model here. A run_table is a List (rows) of tuples (columns),
        representing each run performed"""
        factor1 = FactorModel("ocr_library", ['paddle', 'tesseract'])
        factor2 = FactorModel("document_type", ['Old_books_2noise', 'Old_books_Arabic', 'Old_books_No_noise', 'Book', 'Newspaper', 'notes', 'slides'])
        factor3 = FactorModel("dataset", ['Noisy_Dataset', 'Omni_Dataset'])
        factor4 = FactorModel("sample_size", [1,20])
        factor5 = FactorModel("language", ['eng', 'ara'])
        self.run_table_model = RunTableModel(
            factors = [factor1, factor2, factor3, factor4, factor5],
            exclude_combinations=[
                {factor2: ['Old_books_2noise', 'Old_books_Arabic', 'Old_books_No_noise'], factor3: ['Omni_Dataset']},
                {factor2: ['Book', 'Newspaper', 'notes', 'slides'], factor3: ['Noisy_Dataset']},
                {factor2: ['Old_books_No_noise', 'Old_books_2noise', 'Book', 'Newspaper', 'notes', 'slides'], factor5: ['ara']},
                {factor2: ['Old_books_Arabic'], factor5: ['eng']},
            ],
            data_columns=["energy", "runtime", "memory"],
            repetitions=30,
            shuffle=True,
        )
        return self.run_table_model

    def before_experiment(self) -> None:
        """Perform any activity required before starting the experiment here
        Invoked only once during the lifetime of the program."""
        try:
            os.mkdir("experiments/new_runner_experiment/test_run")
        except FileExistsError:
            pass
        
        cmd = (
            f"{sys.executable}"
            f"  run_paddle.py"
            f"  --sample-size 10"
            f"  --seed 42"
            f"  --document-type Old_books_2noise"
            f"  --dataset Noisy_Dataset"
            f"  --run-dir test_run"
            f"  --language-type eng"
            f"  > /dev/null 2>&1"
        )

        self.profiler = EnergiBridge(target_program=f"bash -c '{cmd}'",
                                     out_file=Path("experiments/new_runner_experiment/test_run/energibridge.csv"))
        self.profiler.start()
        self.target = self.profiler.process
        self.target.wait()
        self.profiler.stop(wait=True)

    def before_run(self) -> None:
        """Perform any activity required before starting a run.
        No context is available here as the run is not yet active (BEFORE RUN)"""
        pass

    def start_run(self, context: RunnerContext) -> None:
        """Perform any activity required for starting the run here.
        For example, starting the target system to measure.
        Activities after starting the run should also be performed here."""
        pass       

    def start_measurement(self, context: RunnerContext) -> None:
        """Perform any activity required for starting measurements."""

        print(f"Starting run with parameters: {context.execute_run}")

        cmd = (
            f"{sys.executable}"
            f"  run_{context.execute_run['ocr_library']}.py"
            f"  --sample-size {context.execute_run['sample_size']}"
            f"  --seed 42"
            f"  --document-type {context.execute_run['document_type']}"
            f"  --dataset {context.execute_run['dataset']}"
            f"  --run-dir {context.run_dir.name}"
            f"  --language-type {context.execute_run['language']}"
            f"  > /dev/null 2>&1"
        )

        self.profiler = EnergiBridge(target_program=f"bash -c '{cmd}'",
                                     out_file=context.run_dir / "energibridge.csv")

        self.profiler.start()
        self.target = self.profiler.process
    def interact(self, context: RunnerContext) -> None:
        """Perform any interaction with the running target system here, or block here until the target finishes."""
        self.target.wait()

    def stop_measurement(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping measurements."""
        stdout = self.profiler.stop(wait=True)

    def stop_run(self, context: RunnerContext) -> None:
        """Perform any activity here required for stopping the run.
        Activities after stopping the run should also be performed here."""
        pass

    def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
        """Parse and process any measurement data here.
        You can also store the raw measurement data under `context.run_dir`
        Returns a dictionary with keys `self.run_table_model.data_columns` and their values populated"""
        
        eb_log, eb_summary = self.profiler.parse_log(self.profiler.logfile, 
                                                     self.profiler.summary_logfile)

        return {"energy": eb_summary["total_joules"],
                "runtime": eb_summary["runtime_seconds"], 
                "memory": max(eb_log["USED_MEMORY"].values())}

    def after_experiment(self) -> None:
        """Perform any activity required after stopping the experiment here
        Invoked only once during the lifetime of the program."""
        pass

    # ================================ DO NOT ALTER BELOW THIS LINE ================================
    experiment_path:            Path             = None