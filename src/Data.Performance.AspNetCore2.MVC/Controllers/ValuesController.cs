using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Data.Performance.AspNetCore2.MVC.Controllers
{
    [Produces("application/json")]
    [Route("api")]
    public class ValuesController : Controller
    {

        /// <summary>
        /// Gets the current version of SecurityAPI.  Also acts as a "Health check"
        /// </summary>
        /// <remarks>
        /// <b>Authorization:</b> open
        /// </remarks>
        [HttpGet("values")]
        public IEnumerable<string> GetApiStatus()
        {
            var assemblyVersion = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();

            //var data = new List<object>();
            //data.Add(new { api = "aspnetcore2.mvc" });
            //data.Add(new { version = assemblyVersion });

            //return Json(data);

            //return new string[] { "value1", "value2" };
            
            return new string[] { "api = aspnetcore2.webapi", $"version = {assemblyVersion}" };

            //var jobj =
            //    new JObject(
            //        new JProperty("api", "securityapi"),
            //        new JProperty("version", assemblyVersion));

            //return new ObjectResult(jobj);
        }
    }
}