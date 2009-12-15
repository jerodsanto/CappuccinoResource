/*
 * Jakefile
 * test
 *
 */
 
var ENV = require("system").env,
    FILE = require("file"),
    task = require("jake").task,
    OS = require("os"),
    FileList = require("jake").FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";
 
task ("test", function()
{
    var tests = new FileList('tests/*Test.j');
    var cmd = ["ojtest"].concat(tests.items());
    var cmdString = cmd.map(OS.enquote).join(" ");
 
    var code = OS.system(cmdString);
    if (code !== 0)
        OS.exit(code);
});
