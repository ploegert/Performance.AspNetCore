# A naive Performance Evaluation of Azure App Service

## Overview
The purpose of this project is to provide a baseline performance indicator when comparing different services hosted in Azure. 

## Project Context:
When deploying various Asp.Net Core apps (using various frameworks including .netcore 2.0, .netcore 1.1, .net Framework 4.6.1 ), with our business logic, we are seeing very poor performing Azure Web App deploymetns where we see < 100 Requests/Sec.

To find what one might expect as a baseline from an Azure App Service deployment vs a VM deployment, we decided we needed to do an analyatlyic assessment of the different permutations across different dotnet frameworks against how Azure App Service performs vs persistent VMs hosted in azure.

### Testing Web App
* The goal was to use the most basic of project with the bare minimum dependencies
* use as much as the Default out of the box configuration - similar to executing ```dotnet new web```
* Have two test cases:
  1. "**static**" web page - A web controller that given a "GET" request, would return back a string of characters - similar to the default "ValuesController" that generates an api/values endpoint that returns a string. As this is just a string of characters, we would expect that this would be best performant Controller call that would exist.
  2. "**status**" web page - A web controller that given a "GET" request, would grab the version of the binary dll, and return that back as a string. This would be expected to perform nearly the equivelent of the "Static" call, but perform slightly worse as it would need to do a file read to get the dll version.

### Asp.Net Benchmarch Numbers
Based upon this, we were hoping that we'd see performance numbers similar to Asp.Net benchmarks (https://github.com/aspnet/benchmarks), which if you look at the numbers, it calls out a Asp.net 4.6 IIS hosted Asp.net app can recieve 51k Requests per second. It's worth noting that these tests execute on two physical machines that are connected via a physical switch - meaning it would not be reasonable to expect these performance numbers in Azure - But still...it's a heck of a place to start.

It's also worth noting that they are using a tool called wrk (https://github.com/wg/wrk) to generate the load for these tests. 

Detailed Results are called out here: https://aka.ms/aspnet/benchmarks.

## Naive Performance Expermentation - Azure App Service Edition
Before finding the optimal deployment mechanism (VM scale set vs App Service), the basis of our test was to first find the upper limit of what azure app service could handle.

### Server Configuration
To make this a reproducable test, We used the following configuration/requirements
* The azure deployment should consist of an ARM template that deploys:
    - Web Hosting Plan
    - Web Application
* All Azure Hosting Plans would use the "Standard" vm type of size Large (S3)
    - 4 cores
    - 7 GB RAM
* minimize any custom Web server optimizations - basically see what we can get "out of the box" when deploying the app service

### Asp.net Solution setup
So we spun up a solution called "Data.Performance" that had several solutions:
1. Create a base "Deploy" project for the ARM Template
    * **Project Name: "Data.Performance.Deploy"**
    * Used VS2017 to create a new Resource Group Deployment project
    * Created Template under "WebSiteTests" folder that would deploy:
        * qty (4) Azure App Hosting Plan servers of a given size (by parameter file)
        * qty (4) Azure App Service Web Apps 
2. .Net Core project that uses the ```netcoreapp2.0``` runtime framework
    * **Project Name:** ==> **"Data.Performance.AspNetCore2.WebAPI"**
    * **Project Location:** ==> **"Data.Performance.BaseTests\src\Data.Performance.AspNetCore2.WebAPI\"**
    * Used VS2017 to create a new project using File->New Project, and selecting the base Asp.net Core 2.0 web api project
    * Create a controller called "StatusController.cs" that would return back the version of the API in string notation when /status was visited
    * Create a controller called "StaticController.cs" that would return back a static string when /static is visited.
3. .Net Core project that uses the ```netcoreapp1.1```  runtime framework
    * **Project Name:** ==> **"Data.Performance.AspNetCore11.WebAPI"**
    * **Project Location:** ==> **"Data.Performance.BaseTests\src\Data.Performance.AspNetCore11.WebAPI\"**
    * Used VS2017 to create a new project using File->New Project, and selecting the base Asp.net Core 1.1 web api project
    * Create a controller called "StatusController.cs" that would return back the version of the API in string notation when /status was visited
    * Create a controller called "StaticController.cs" that would return back a static string when /static is visited.
4. .Net Core project that uses the ```net461```  runtime framework
    * **Project Name:** **"Data.Performance.AspNetCore461.2015"**
    * **Project Location:** ==> **"Data.Performance.BaseTests\src\Data.Performance.AspNetCore461.2015"**
    * Project creation wasn't easy unfortunatly. After several failed configuration permutations, I ended up: 
        * Falling back to launching VS2015, 
        * Creating a new asp.net core 1.1 project (Xproj)
        * Changed runtime from netcoreapp1.1 to net461
        * ran ```dotnet migrate``` from command line to convert it to a csproj
    * Create a controller called "StatusController.cs" that would return back the version of the API in string notation when /status was visited
    * Create a controller called "StaticController.cs" that would return back a static string when /static is visited.
5. [FUTURE - Not implemented yet] Asp.Net Core project that uses the ```netcoreapp1.0```  runtime framework
    * **Project Name:** "Data.Performance.AspNetCore10.WebAPI"
    * Use VS2017 to create a new project using File->New Project, and selecting the base Asp.net Core 1.1 web api project
    * Create a controller called "StatusController.cs" that would return back the version of the API in string notation when /status was visited
    * Create a controller called "StaticController.cs" that would return back a static string when /static is visited.
6. [FUTURE - Not implemented yet] Asp.Net project that uses the **NON-NETCORE -- ie full runtime** of ```net461``` full runtime framework
    * **Project Name:** "Data.Performance.AspNet461.WebAPI"
    * Use VS2017 to create a new project using File->New Project, and selecting the base Asp.net Core 1.1 web api project
    * Create a controller called "StatusController.cs" that would return back the version of the API in string notation when /status was visited
    * Create a controller called "StaticController.cs" that would return back a static string when /static is visited.

### Deploying the Web Apps to the App Service
* Initially, my goal was to not need to create a build definition & add deployment steps
* This quickly fell apart when I realized that for whatever reason I couldn't use the "Publish" command in Visual Studio to deploy the .net Core project with framworks for net461 or aspnetcore1.1. Even tho the deployment would "Succeed", the publish commands weren't copying out the .dll/.exe from the project
* I ended up setting up a build defintion that had the steps for each project/deployment:
    * dotnet restore
    * dotnet build
    * dotent publish (to .zip)
    * stop webapp 
    * deploy webapp from .zip
    * start webapp
* This sucked that I had to got this length, but it ended up doing the trick to deploy the project. I really need to circle back on why i can't deploy net461 via publish.

### Executing the Load Tests:
* We have used Microsoft Load tests in the past, but recently our dev team moved over to using Blazemeter (https://www.blazemeter.com/).
* I setup a Project called "Justin-Tests", and under that I created a bunch of tests:

    | Project Type | Framework     | Test Type | 
    | ------------ |:-------------:|:-------------:|
    | Asp.Net Core | netcore2.0 | Static Web Page | 
    | Asp.Net Core | netcore2.0 | Status Web Page | 
    | Asp.Net Core | netcore1.1 | Static Web Page |
    | Asp.Net Core | netcore1.1 | Status Web Page |
    | Asp.Net Core | net461 | Static Web Page |
    | Asp.Net Core | net461 | Status Web Page |

* In each test, i used a baseline of 1500 virtual Users, which resulted in Blazemeter spinning up 
    * 3 "engines" with 500 threads per engine. 
    * Each engine would have a different IP, so this would result in Azure getting pinged by 3 different IPs, with 500 threads off of each IP
    * a Rampup of 0 seconds (no ramp-up)
    * Infinite amount of Iterations (just keep hitting the same url over and over)
    * run for a duration of 2 minutes
    * Delay between iterations of 0 seconds (no delay )
    * Urls that were getting executed by jmeter looked like:
        * https://datad-ptest-netfx-ws.azurewebsites.net/static
        * https://datad-ptest-netfx-ws.azurewebsites.net/status


## Performance Results
* So in thinking that we'd get somewhere near 52000 rps, we fell to a < 1000 rps for a single server. 
* Based on other tests where we got an equivelent App Serivce, we were seeing that the vm hosted instances were getting 10,000 rps

### Results - .NetCore 2.0 
* I would have expected that if the a single web app server were to return 800 rps, that two servers would get 1600. This wasn't the case.


| Host    | Name         | Framework   | Test Type |  Virtual Users | Host Count | Req/Sec | % Error | Avg Response | 
| ------- | ------------ | ----------- | ----- | :-------------:  | :-----:  | :-----:  | :-----:  | :-----: |
| Web App | Asp.Net Core | netcore2.0 | Static (read string) | 1500 | 1 vm | 876 rps | 0% | 1.7 s |
| Web App | Asp.Net Core | netcore2.0 | Status (read file) | 1500 | 1 vm | 785 rps | 0% | 1.89 s |
| Web App | Asp.Net Core | netcore2.0 | Static (read string) | 1500 | 2 vm | 1131 rps | 0% | 1.31 s |
| Web App | Asp.Net Core | netcore2.0 | Status (read file) | 1500 | 2 vm | 1213 | 0% | 1.23 s |
| Web App | Asp.Net Core | netcore2.0 | Static (read string) | 3000 | 10 vm | 6665.97 | 66% | .44 s |
| VM ScaleSet | Asp.Net Core | netcore2.0 | Static (read string) | 1500 | 1 vm | not run | | |
| VM ScaleSet | Asp.Net Core | netcore2.0 | Status (read file) | 1500 | 1 vm | not run | | |
| VM ScaleSet | Asp.Net Core | netcore2.0 | Static (read string) | 1500 | 2 vm | not run | | |
| VM ScaleSet | Asp.Net Core | netcore2.0 | Status (read file) | 1500 | 2 vm | not run | | |
| VM ScaleSet | Asp.Net Core | netcore2.0 | Static (read string) | 3000 | 10 vm | not run | | |

![docs/20results.png](docs/20results.png)

* When scaling from 2 vm hosts to 10, the error rate when drastically up where basically the net success was minimal to a shocking number
* If you compare the previous image of 10 hosts to a one with 2 paas hosts, the image looks like the image below - with 0% errors. 

![docs/20results.png](docs/20success.png)

### Results - .NetCore 1.1 
| Host    | Name         | Framework   | Test Type |  Virtual Users | Host Count | Req/Sec | % Error | Avg Response | 
| ------- | ------------ | ----------- | ----- | :-------------:  | :-----:  | :-----:  | :-----:  | :-----: |
| Web App | Asp.Net Core | netcore1.1 | Static (read string) | 1500 | 1 vm | 889 rps | 0% | 1.68 s |
| Web App | Asp.Net Core | netcore1.1 | Status (read file) | 1500 | 1 vm | 767 rps | 0% | 1.60 s |
| VM ScaleSet | Asp.Net Core | netcore1.1 | Static (read string) | 1500 | 1 vm | not run | | |
| VM ScaleSet | Asp.Net Core | netcore1.1 | Status (read file) | 1500 | 1 vm | not run | | |

### Results - .NetCore netfx(4.6.1 )
| Host    | Name         | Framework   | Test Type |  Virtual Users | Host Count | Req/Sec | % Error | Avg Response | 
| ------- | ------------ | ----------- | ----- | :-------------:  | :-----:  | :-----:  | :-----:  | :-----: |
| Web App | Asp.Net Core | net461 | Static (read string) | 1500 | 1 vm | 722 rps | 0% | 2.09 s |
| Web App | Asp.Net Core | net461 | Status (read file) | 1500 | 1 vm | 753 rps | 0% | 2.0 s |
| VM ScaleSet | Asp.Net Core | net461 | Static (read string) | 1500 | 1 vm | not run | | |
| VM ScaleSet | Asp.Net Core | net461 | Status (read file) | 1500 | 1 vm | not run | | |


## Next Steps:

* As of 1/9/2018 @ 6pm, I've completed the Azure Web App Deployments & tests
* I've defined the VM Scale Set ARM template & deployed an intial instance to Azure, where source code is: 
    * Data.Performance.BaseTests\src\Data.Performance.Deploy\ScaleSet
* Left to dO:
    * Need to update the ARM deployment to deploy 3 seperate scale sets in the same network with 3 different load balancers (for each project type)
    * Configure ARM deployment to deploy each of the VM type
    * Ensure the iis site is deployed properly and works
    * Re-Run load tests against the scale sets wit the same permutations that we did on the App Service tests
