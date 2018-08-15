object PEG {
  type Parser = String => Option[String]
  implicit class Extension(a: => Parser) {
    def ~(b: => Parser): Parser = in => a(in).flatMap(b) // e1 e2
    def /(b: => Parser): Parser = in => a(in).orElse(b(in)) // e1 / e2
    def unary_! : Parser = in => a(in) match { // !e
      case Some(_) => None
      case None => Some(in)
    }
    def s(literal: String): Parser = in => // " "
      if(in.startsWith(literal)) Some(in.substring(literal.length))
      else None
  }
}
