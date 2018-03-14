using System;

namespace Msi.Tests
{
    class Program
    {
        static void Main(string[] args)
        {
            string msiFile = Environment.GetEnvironmentVariable("HOST_MSI");
            Console.WriteLine(msiFile);
        }
    }
}
