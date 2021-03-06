package ducttape.hyperdag

import ducttape.util.Optional

class HyperEdge[H,E](private[hyperdag] val id: Int, val h: H, val e: Seq[E]) {
  override def hashCode() = id
  override def equals(that: Any) = that match { case other: HyperEdge[_,_] => (other.id == this.id) }
  override def toString() = {
    val hStr = Optional.toOption(h) match {
      case None => "ID=%d".format(id)
      case Some(_) => h.toString + ":" + id
    }
    val eStr = e.filter { _ != null } match {
      case Seq() => ""
      case _ => ":" + e.mkString("\n")
    }
    hStr + eStr
  }
}
