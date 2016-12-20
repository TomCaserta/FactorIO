// TODO: Automate going through the factorio API to Generated serializers

var attribs = document.querySelectorAll(".param-type");
var cObj = window.location.pathname.split("/")[2].split(".")[0];
var cName = cObj.replace("Lua","").toLowerCase();
console.log("function serialize"+cObj +" ("+cName+")");
console.log(" if("+cName+" == nil) then return nil; end;");
for (var i = 0; i < attribs.length; i++){
  var curr = attribs[i];
  var a = curr.children[0];
  console.log(a);
  var href = a.getAttribute("href");
  if (href.indexOf("Builtin-Types.html") == -1) {
  //  console.log("Custom serializer required for: ",href);
  }
  else {
    var name = curr.parentNode.parentNode.children[0].innerText.trim();
    console.log(name + " = "+ cName+"."+name+",");
  }
}
