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
	    Console.WriteLine("test dri!!");
	    string msiFile = Environment.GetEnvironmentVariable("HOST_MSI");
	    Console.WriteLine(@msiFile);
	    using (var database = new Database(@msiFile, DatabaseOpenMode.ReadOnly))
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
