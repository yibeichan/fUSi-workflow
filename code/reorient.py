import pydra
import nipype.interfaces.afni as afni
from pydra.engine.task import FunctionTask
from pydra.engine import Workflow

@pydra.mark.task
@pydra.mark.annotate({"return": {"out_file": str}})
def deoblique_function(infile, outpath):
    deoblique = afni.Warp()
    deoblique.inputs.in_file = infile
    deoblique.inputs.oblique2card = True
    deoblique.inputs.out_file = f"{outpath}/angio_raw_deo.nii.gz"
    deoblique.run()
    return {"out_file": deoblique.inputs.out_file}


@pydra.mark.task
@pydra.mark.annotate({"return": {"out_file": str}, "inputs": {"infile": str, "outpath": str}})
def flip_function(infile, outpath):
    flip = afni.LRFlip()
    flip.inputs.in_file = infile
    flip.inputs.out_file = f"{outpath}/angio_raw_deo_ryf.nii.gz"
    flip.run()
    return {"out_file": flip.inputs.out_file}


@pydra.mark.task
@pydra.mark.annotate({"return": {"out_file": str}, "inputs": {"infile": str, "outpath": str}})
def copy_function(infile, outpath):
    copy = afni.Copy()
    copy.inputs.in_file = infile
    copy.inputs.out_file = f"{outpath}/angio_raw_deo_ryf_rf.nii.gz"
    copy.run()
    return {"out_file": copy.inputs.out_file}

# Configure directories and files
fullpath_file = "/opt/home/data/Florian_raw_data/15_NoSAT_TOF_3D_multi-slab_0.13mm_iso.nii"
output_dir = "/opt/home/output/Florian_preproc/pydra_test"

# Workflow setup using FunctionTask
wf = Workflow(name="afni_reorient", input_spec=["infile", "outpath"], infile=fullpath_file, outpath=output_dir)
wf.add(FunctionTask(deoblique_function, name="deoblique", infile=wf.lzin.infile, outpath=wf.lzin.outpath))
wf.add(FunctionTask(flip_function, name="flip", infile=wf.deoblique.lzout.out_file, outpath=wf.lzin.outpath))
wf.add(FunctionTask(copy_function, name="copy", infile=wf.flip.lzout.out_file, outpath=wf.lzin.outpath))

# Connecting tasks and setting output
wf.set_output([("out_file", wf.copy.lzout.out_file)])

# Execute the workflow
with pydra.Submitter(plugin="cf") as sub:
    sub.run(wf)

result = wf.result()
print("Workflow completed with final output:", result.output.out_file)