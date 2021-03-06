package ducttape.exec

import ducttape.workflow.RealTask
import ducttape.workflow.Realization
import java.io.File
import grizzled.slf4j.Logging

/**
 * Unlike the FullTaskEnvironment, does not require knowledge of packageVersions,
 * but does not provide full list of environment variables
 */
class TaskEnvironment(val dirs: DirectoryArchitect,
                      val task: RealTask) extends Logging {
  
  // grab input paths -- how are these to be resolved?
  // If this came from a branch point, its source vertex *might* not
  // no knowledge of that branch point. However, we might *still* have
  // knowledge of that branch point at the source:
  // 1) If that branch point is defined in multiple places (i.e. a factored HyperDAG)
  //    and this the second time along an unpacked path that we encountered that
  //    branch point, then we might still need to keep it. This state information
  //    along a path is maintained by the constraintFilter.
  // 2) If the visibility of a branch point X is conditioned on the choice by another
  //    branch point Y?
  // TODO: Move unit tests from LoonyBin to ducttape to test for these sorts of corner cases
  // TODO: Then associate Specs with edge info to link parent realizations properly
  //       (need realization FOR EACH E, NOT HE, since some vertices may have no knowlege of peers' metaedges)
  val inputs: Seq[(String, String)] = for (inputVal <- task.inputVals) yield {
    val inFile = dirs.getInFile(inputVal.origSpec, task.realization,
                                inputVal.srcSpec, inputVal.srcTask, inputVal.srcReal)
    debug("For inSpec %s with srcSpec %s and srcReal %s with parent task %s, got path: %s".format(
            inputVal.origSpec, inputVal.srcSpec, inputVal.srcReal, inputVal.srcTask, inFile))
    (inputVal.origSpec.name, inFile.getAbsolutePath)
  }
    
  // set param values (no need to know source active branches since we already resolved the literal)
  // TODO: Can we get rid of srcRealization or are we resolving parameters incorrectly sometimes?
  val params: Seq[(String,String)] = for (paramVal <- task.paramVals) yield {
    debug("For paramSpec %s with srcSpec %s, got value: %s".format(
             paramVal.origSpec, paramVal.srcSpec, paramVal.srcSpec.rval.value))
    (paramVal.origSpec.name, paramVal.srcSpec.rval.value)
  }

  // assign output paths
  val outputs: Seq[(String, String)] = for (outSpec <- task.outputs) yield {
    val outFile = dirs.assignOutFile(outSpec, task.taskDef, task.realization)
    debug("For outSpec %s got path: %s".format(outSpec, outFile))
    (outSpec.name, outFile.getAbsolutePath)
  }
  
  val where = dirs.assignDir(task)
  val stdoutFile = new File(where, "ducttape_stdout.txt")
  val stderrFile = new File(where, "ducttape_stderr.txt")
  val exitCodeFile = new File(where, "ducttape_exit_code.txt")
  val versionFile = new File(where, "ducttape_version.txt")

  // TODO: XXX: Do we still need this file?
  val invalidatedFile = new File(where, "ducttape.INVALIDATED")

  // the lock file *must* be placed outside of the where directory
  // since we must sequentially acquire the lock and *then* atomically move
  // the where directory to the attic (including its exact inode, in case
  // any running processes still have that inode open)
  val lockFile = new File(where.getParentFile, "%s.LOCK".format(where.getName))
}

/**
 * Includes all environment variables, but requires knowledge of packgeVersions
 */
class FullTaskEnvironment(dirs: DirectoryArchitect,
                          val packageVersions: PackageVersioner,
                          task: RealTask) extends TaskEnvironment(dirs, task) {
  val packageNames: Seq[String] = task.packages.map(_.name)
  val packageBuilds: Seq[BuildEnvironment] = {
    packageNames.map { name =>
      val packageVersion = packageVersions(name)
      new BuildEnvironment(dirs, packageVersion, name)
    }
  }
  val packageEnvs: Seq[(String,String)] = {
    packageBuilds.map(build => (build.packageName, build.buildDir.getAbsolutePath) )
  }

  lazy val env = inputs ++ outputs ++ params ++ packageEnvs
}
