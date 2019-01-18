package com.github.kmizu.usparse

import org.scalatest.{DiagrammedAssertions, FunSpec}

class CalculatorSpec extends FunSpec with DiagrammedAssertions {
  object Calculator {
    def E: P[Int] = rule(A)
    def A: Parser[Int] = rule {
      M ~ ($("+") ~ M | $("-") ~ M).* ^^ {case x ~ ys =>
        ys.foldLeft(x){ case (l, op ~ r) => if(op == "+") l + r else l -r }
      }
    }
    def M: Parser[Int] = rule {
      P ~ ($("*") ~ P | $("/") ~ P).* ^^ { case x ~ ys =>
        ys.foldLeft(x) { case (l, op ~ r) => if (op == "*") l * r else l / r }
      }
    }
    def P: P[Int] = rule{
      (for { _ <- $("("); e <- E; _ <- $(")")} yield e) | number
    }
    def number: P[Int] = rule {
      ('0' to '9').map{c => $(c.toString) ^^ (_.toInt)}.reduce((p1, p2) => p1 | p2)
    }
  }

  val parser = Calculator.E

  describe("A Calculator") {
    var input = ""
    it("should parse correct expressions") {
      input = "1+2*3"
      assert(parser(input) == Success(7, ""))
      input = "1+5*3/4"
      assert(parser(input) == Success(4, ""))
      input = "(1+5)*3/2"
      assert(parser(input) == Success(9, ""))
    }
    it("cannot parse incorrect expressions, which ends with unexpected EOF") {
      input = "1+ "
      assert(parser(input) == Success(1, "+ "))
    }

    it("cannot parse incorrect expressions, which contains spaces") {
      input = "(1-5) *3/2"
      assert(parser(input) == Success(-4, " *3/2"))
    }
  }
}
