using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace Data.Performance.AspNet461._2015.Controllers
{
    [Route("[controller]")]
    public class StaticController : Controller
    {
        [HttpGet]
        public IEnumerable<string> Get()
        {
            var api = "aspnetcore461.webapi";
            var ver = "STATIC";
            return new string[] { $"api = {api}", $"version = {ver}" };
        }

    }
}
