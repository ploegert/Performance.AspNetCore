//using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Threading.Tasks;
//using Microsoft.AspNetCore.Mvc;
//using System.Reflection;

//namespace Data.Performance.AspNetCore11.Controllers
//{
//    [Route("api/[controller]")]
//    public class ValuesController : Controller
//    {
//        // GET api/values
//        [HttpGet]
//        public IEnumerable<string> Get()
//        {
//            //return new string[] { "value1", "value2" };
//            //var assemblyVersion = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version.ToString();
//            var assemblyVersion = typeof(ValuesController).GetTypeInfo().Assembly.GetName().Version.ToString();

//            return new string[] { "api = aspnetcore2.webapi", $"version = {assemblyVersion}" };
//        }

//        [HttpGet("/static")]
//        public IEnumerable<string> GetStatic()
//        {
//            return new string[] { "api = aspnetcore2.webapi", $"version = STATIC" };
//        }

//        // GET api/values/5
//        [HttpGet("{id}")]
//        public string Get(int id)
//        {
//            return "value";
//        }

//        // POST api/values
//        [HttpPost]
//        public void Post([FromBody]string value)
//        {
//        }

//        // PUT api/values/5
//        [HttpPut("{id}")]
//        public void Put(int id, [FromBody]string value)
//        {
//        }

//        // DELETE api/values/5
//        [HttpDelete("{id}")]
//        public void Delete(int id)
//        {
//        }
//    }
//}
