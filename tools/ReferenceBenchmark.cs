// Original harness; compile with the four unchanged upstream model sources.
using System;
using System.IO;
using System.Text.Json;
using System.Diagnostics;
using System.Reflection;
using System.Linq;
using System.Collections.Generic;
class ReferenceBenchmark {
 static void Main(){string line;while((line=Console.ReadLine())!=null){try{
  var j=JsonDocument.Parse(line).RootElement;
  var watch=Stopwatch.StartNew();
  var model=new OverlappingModel(j.GetProperty("name").GetString(),j.GetProperty("size").GetInt32(),j.GetProperty("width").GetInt32(),j.GetProperty("height").GetInt32(),true,false,j.GetProperty("symmetry").GetInt32(),false,Model.Heuristic.Entropy);
  double learnMs=watch.Elapsed.TotalMilliseconds;watch.Restart();
  bool solved=model.Run(j.GetProperty("seed").GetInt32(),-1);
  double solveMs=watch.Elapsed.TotalMilliseconds;
  if(solved)model.Save(j.GetProperty("output").GetString());
  var flags=BindingFlags.NonPublic|BindingFlags.Instance;
  var colors=(List<int>)typeof(OverlappingModel).GetField("colors",flags).GetValue(model);
  var patterns=((List<byte[]>)typeof(OverlappingModel).GetField("patterns",flags).GetValue(model)).Select(p=>p.Select(c=>colors[c]).ToArray()).ToArray();
  Console.WriteLine("RESULT "+JsonSerializer.Serialize(new{solved,learnMs,solveMs,totalMs=learnMs+solveMs,patterns}));
 }catch(Exception e){Console.WriteLine("RESULT "+JsonSerializer.Serialize(new{error=e.ToString()}));}}}
}
