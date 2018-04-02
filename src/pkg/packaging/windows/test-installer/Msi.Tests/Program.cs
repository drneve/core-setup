using System;
using System.IO;
using Microsoft.Deployment.WindowsInstaller;
using Xunit;
using System.Collections.Generic;

namespace Msi.Tests
{
    public class Program
    {
	[Fact]
	public void ProductNameTest()
        {
	    string prodVersion = Environment.GetEnvironmentVariable("PROD_VERSION");
	    //Console.WriteLine(prodVersion);
	    
	    var msiList = Environment.GetEnvironmentVariable("MSI_LIST");
	    string[] lines = System.IO.File.ReadAllLines(msiList);
	    foreach( string msi in lines ) 
	    {
		    using (var database = new Database(msi, DatabaseOpenMode.ReadOnly))
		    {
			    string prodName = database.ExecutePropertyQuery("ProductName");
			    Assert.True(prodName.Contains(prodVersion), "Different brand name");
	//		    IList<string> list = database.ExecuteStringQuery("SELECT `ComponentId` FROM `Component` WHERE `Component`='{0}'", new object[]{"Dotnet_CLI_SharedHost_16.64.26314_x64"});
	//		    Assert.Equal("{82516259-FF21-446E-A432-1FFCA5A02296}" , list[0]);
		    }
	    }	
	}

    }
}
