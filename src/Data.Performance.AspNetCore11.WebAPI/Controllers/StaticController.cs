using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using System.Reflection;

namespace Data.Performance.AspNetCore11.Controllers
{
    [Route("[controller]")]
    public class StaticController : Controller
    {
        [HttpGet]
        public IEnumerable<string> Get()
        {
            var api = "aspnetcore11.webapi";
            var ver = "STATIC";
            return new string[] { $"api = {api}", $"version = {ver}" };
        }

    }
}
