var foo = "bar"   // missing semicolon, should be const or let
console.log(foo))
function doSomething() {
  if (true) {
    return
    console.log("This will never run") // unreachable code
  }
}
doSomething()