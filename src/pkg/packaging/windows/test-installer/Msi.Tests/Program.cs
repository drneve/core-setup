using System;

namespace Msi.Tests
{
    class Program
    {
        static void Main(string[] args)
        {
            string msiFile = Environment.GetEnvironmentVariable("HOST_MSI");
            Console.WriteLine("Test cs program");
            Console.WriteLine(msiFile);
        }
    }
}
