## Snakefile - MRW
##
## @lachlandeer

from pathlib import Path

LOG_ALL = "2>&1"

# --- Import a config file --- #
configfile: "config.yaml"

# --- Iterable Lists --- #

DATA_SUBSET = glob_wildcards(config["src_data_specs"] +
                "{iFile}.json").iFile
DATA_SUBSET = list(filter(lambda x: x.startswith("subset"), DATA_SUBSET))
MODELS      = glob_wildcards(config["src_model_specs"] +
                "{iFile}.json").iFile
FIGS        = glob_wildcards(config["src_figures"] +
                    "{iFile}.R").iFile
TABLES      = ["tab01_textbook_solow", "tab02_augment_solow"]

# --- Build Rules --- #

rule all:
    input:
        figures = expand(config["out_figures"] + "{iFigure}.pdf",
                        iFigure = FIGS),
        models = expand(config["out_analysis"] +
                            "{iModel}_ols_{iSubset}.rds",
                              iSubset = DATA_SUBSET,
                              iModel = MODELS),
        tab01 = config["out_tables"] + "tab01_textbook_solow.tex"

rule tab01:
    input:
        script = config["src_tables"] + "tab01_textbook_solow.R",
        estimates = expand(config["out_analysis"] +
                    "{iModel}_ols_{iSubset}.rds",
                     iSubset = DATA_SUBSET,
                     iModel = MODELS)
    output:
        tex = config["out_tables"] + "tab01_textbook_solow.tex"
    params:
        filepath = config["out_analysis"],
        model_exp = "model_solow*.rds"
    log:
        config["log"] + "tab01_textbook_solow.Rout"
    shell:
        "Rscript {input.script} \
            --filepath {params.filepath} \
            --models {params.model_exp} \
            --out {output.tex} > {log} {LOG_ALL}"

rule make_figs:
    input:
        script = config["src_figures"] + "{iFigure}.R",
        data   = config["out_data"] + "mrw_complete.csv",
        subset = config["src_data_specs"] + "subset_intermediate.json",
    output:
        fig = Path(config["out_figures"] + "{iFigure}.pdf"),
    log:
        config["log"] + "{iFigure}.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --subset {input.subset} \
            --out {output.fig} > {log} {LOG_ALL}"

rule solow_model:
    input:
        script = config["src_analysis"] + "estimate_ols_model.R",
        data   = config["out_data"] + "mrw_complete.csv",
        model  = config["src_model_specs"] + "{iModel}.json",
        subset = config["src_data_specs"]  + "{iSubset}.json"
    output:
        model_est = config["out_analysis"] + "{iModel}_ols_{iSubset}.rds"
    log:
        config["log"] + "analysis/{iModel}_ols_{iSubset}.Rout"
    shell:
        "Rscript {input.script} \
            --data {input.data} \
            --model {input.model} \
            --subset {input.subset} \
            --out {output.model_est} \
            > {log} 2>&1"

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
