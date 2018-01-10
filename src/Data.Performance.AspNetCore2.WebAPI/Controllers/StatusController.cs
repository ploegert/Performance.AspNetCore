using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using System.Reflection;

namespace Data.Performance.AspNetCore2.WebAPI.Controllers
{
    [Route("[controller]")]
    public class StatusController : Controller
    {
        // GET api/values
        [HttpGet]
        public IEnumerable<string> Get()
        {
            //return new string[] { "value1", "value2" };
            //var assemblyVersion = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();
            var assemblyVersion = typeof(StatusController).GetTypeInfo().Assembly.GetName().Version.ToString();

            return new string[] { "api = aspnetcore2.webapi", $"version = {assemblyVersion}" };
        }

    }
}
