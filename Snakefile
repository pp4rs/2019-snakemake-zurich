## Snakefile - MRW
##
## @lachlandeer

from pathlib import Path

LOG_ALL = "2>&1"

# --- Import a config file --- #
configfile: "config.yaml"

# --- Iterable Lists --- #

DATA_SUBSETS = ["nonoil", "intermediate", "oecd"]

# --- Build Rules --- #

rule all:
    input:
        models = expand(config["out_analysis"] +
                    "solow_estimates_{iSubset}.rds",
                     iSubset = DATA_SUBSETS)

rule solow_model:
    input:
        script = config["src_analysis"] + "estimate_ols_model.R",
        data   = config["out_data"] + "mrw_complete.csv",
        model  = config["src_model_specs"] + "model_solow.json",
        subset = config["src_data_specs"] + "subset_{iSubset}.json"
    output:
        estimates = Path(config["out_analysis"] + "solow_estimates_{iSubset}.rds")
    log:
        config["log"] + "estimate_ols_model_{iSubset}.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.estimates} > {log} {LOG_ALL}"









rule rename_vars:
    input:
        script = config["src_data_mgt"] + "rename_variables.R",
        data   = config["src_data"] + "mrw.dta"
    output:
        data = Path(config["out_data"] + "mrw_renamed.csv")
    log:
        config["log"] + "rename_variables.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --out {output.data} > {log} {LOG_ALL}"

rule make_variables:
    input:
        script = config["src_data_mgt"] + "gen_reg_vars.R",
        data   = config["out_data"] + "mrw_renamed.csv",
        param  = config["src_data_specs"] + "param_solow.json"
    output:
        data = Path(config["out_data"] + "mrw_complete.csv")
    log:
        config["log"] + "gen_reg_vars.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --param {input.param} \
            --out {output.data} > {log} {LOG_ALL}"

rule clean:
    shell:
        "rm -rf out/*"

rule clean_windows:
    shell:
        "powershell.exe -command \" Remove-Item '.\out'  \
            -include *.csv \
            -recurse\""
