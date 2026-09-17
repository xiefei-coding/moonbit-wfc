using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Collections.Generic;
class Oracle {
 static object Field(object obj,string name){for(Type type=obj.GetType();type!=null;type=type.BaseType){var f=type.GetField(name,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.DeclaredOnly);if(f!=null)return f.GetValue(obj);}throw new Exception(name);}
 static void Main(){string line;while((line=Console.ReadLine())!=null){try{var j=JsonDocument.Parse(line).RootElement;string kind=j.GetProperty("kind").GetString();Model model;
 if(kind=="overlap")model=new OverlappingModel(j.GetProperty("name").GetString(),j.GetProperty("size").GetInt32(),j.GetProperty("width").GetInt32(),j.GetProperty("height").GetInt32(),j.GetProperty("periodicInput").GetBoolean(),j.GetProperty("periodic").GetBoolean(),j.GetProperty("symmetry").GetInt32(),false,Model.Heuristic.Entropy);
 else model=new SimpleTiledModel(j.GetProperty("name").GetString(),j.TryGetProperty("subset",out var subset)?subset.GetString():null,j.GetProperty("width").GetInt32(),j.GetProperty("height").GetInt32(),j.GetProperty("periodic").GetBoolean(),false,Model.Heuristic.Entropy);
 var output=new Dictionary<string,object>();output["weights"]=Field(model,"weights");output["propagator"]=Field(model,"propagator");
 if(kind=="overlap"){var patterns=(List<byte[]>)Field(model,"patterns");var colors=(List<int>)Field(model,"colors");output["patterns"]=patterns.Select(a=>a.Select(b=>colors[b]).ToArray()).ToArray();}else{output["labels"]=Field(model,"tilenames");output["tiles"]=Field(model,"tiles");}
 if(j.TryGetProperty("seed",out var seed)){var watch=System.Diagnostics.Stopwatch.StartNew();bool solved=model.Run(seed.GetInt32(),-1);watch.Stop();output["solved"]=solved;output["elapsedMs"]=watch.Elapsed.TotalMilliseconds;output["observed"]=Field(model,"observed");if(solved&&j.TryGetProperty("output",out var path))model.Save(path.GetString());}
 Console.WriteLine("RESULT "+JsonSerializer.Serialize(output));}catch(Exception e){Console.WriteLine("RESULT "+JsonSerializer.Serialize(new{error=e.ToString()}));}}}
}