object For {
  def doSomething(i: Int): Unit = {}
  def main(args: Array[String]): Unit = {
    var i = 0
    while(i <= 100) {
      doSomething(i)
      i += 1
    }
  }
}
