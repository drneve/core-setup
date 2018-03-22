using System;
//using System.Linq;
using Microsoft.Deployment.WindowsInstaller;
//using Microsoft.Deployment.WindowsInstaller.Linq;

namespace Msi.Tests
{
    class Program
    {
        static void Main(string[] args)
        {
	    Console.WriteLine("blaaa!!");
	    using (var database = new Database(@"C:\ProgramData\Package Cache\{6B62F428-E37B-40DB-8C40-D7C60A4E7CA2}v16.64.26306\dotnet-host-2.1.0-preview2-26306-04-win-x64.msi", DatabaseOpenMode.ReadOnly))
            {
                using (var view = database.OpenView(database.Tables["Property"].SqlSelectString))
                {
                    view.Execute();
                    foreach (var rec in view) using (rec)
                        {
                            Console.WriteLine("{0} = {1}", rec.GetString("Property"), rec.GetString("Value"));
                        }
                }
            }
       }
    }
}
