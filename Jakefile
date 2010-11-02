/*
 * Jakefile
 * test
 *
 */

require('./common.jake');

var ENV = require("system").env,
    FILE = require("file"),
	OS = require("os"),
	JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = JAKE.FileList,
    stream = require("narwhal/term").stream,
    framework = require("cappuccino/jake").framework,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Release";

framework ("CappuccinoResource", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "CappuccinoResource.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("CappuccinoResource");
    task.setIdentifier("org.sant0sk1.cappuccinoResource");
    task.setVersion("1.0");
    task.setAuthor("Jerod Santo");
    task.setEmail("nospam @nospam@ jerodsanto.net");
    task.setSummary("CappuccinoResource");
    task.setSources(new FileList("Framework/CappuccinoResource/*.j"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task("build", ["CappuccinoResource"]);

task("debug", function()
{
    ENV["CONFIG"] = "Debug"
    JAKE.subjake(["."], "build", ENV);
});

task("release", function()
{
    ENV["CONFIG"] = "Release"
    JAKE.subjake(["."], "build", ENV);
});

task ("test", function()
{
    var tests = new FileList('Tests/*Test.j');
    var cmd = ["ojtest"].concat(tests.items());
    var cmdString = cmd.map(OS.enquote).join(" ");

    var code = OS.system(cmdString);
    if (code !== 0)
        OS.exit(code);
});
