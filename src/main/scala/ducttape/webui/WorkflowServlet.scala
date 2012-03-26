package ducttape.webui

import javax.servlet.http._
import java.io._

class WorkflowServlet(workflowDirs: Seq[File]) extends HttpServlet {
  import ducttape.viz._
  import ducttape.util._

  //val db = new WorkflowDatabase("workflow.db")
  val dotFile = new File(workflowDirs.head, ".xdot") // TODO: This should actually just be .dot
  val timeout = 15 // poll file every N secs

  var lastChanged: Long = 0 // unix timestamp
  def pollFileForUpdates() {
    while(lastChanged == dotFile.lastModified) {
      Thread.sleep(timeout*1000)
    }
    lastChanged = dotFile.lastModified
    System.err.println("Detected file change")
  }

  def sendFile(pw: PrintWriter) {
    val dot = Files.read(dotFile).mkString("\n")
    val xdot = GraphViz.compileXDot(dot)
    System.err.println("Sending new XDot graph")
    pw.println(xdot)
    pw.flush
  }

  override def init() {}
  override def doGet(req: HttpServletRequest, resp: HttpServletResponse) = service(req, resp)
  override def service(req: HttpServletRequest, resp: HttpServletResponse) { 
    val pw = resp.getWriter
    req.getParameter("queryType") match {
      case "first" => {
        sendFile(pw)
      }
      case "update" => {
        pollFileForUpdates
        sendFile(pw)
      }
      case _ @ t => {
        throw new RuntimeException("Unknown queryType: " + t)
      }
    }
  }
}