var sugarcrm = require('node-sugarcrm');

DemoController = (function() {

    function DemoController() {}

    DemoController.prototype.host = "localhost";

    DemoController.prototype.servicePath = "/sugarcrm/service/v2/rest.php";

    DemoController.prototype.username = "admin";

    DemoController.prototype.password = "sugar123";

    DemoController.prototype.onGetResult = function(sender, err, result) {
      var cbOnGetWithRelatedDone, self;
      console.log("Result of Get:");
      console.log(result);
      self = controller;
      console.log(self);
      cbOnGetWithRelatedDone = function(sender, error, result) {
        return self.onGetWithRelatedResult(sender, error, result);
      };
      return sender.getEntries("Accounts", {
        "Accounts": ['id', 'name'],
        "Cases": ['id', 'status']
      }, null, cbOnGetWithRelatedDone);
    };

    DemoController.prototype.onGetWithRelatedResult = function(sender, err, result) {
      console.log("Result of getEntries:");
      return console.log(result);
    };

    DemoController.prototype.onGetEntriesCount = function(sender, err, resultCount) {
      var self;
      console.log("Entries count is " + resultCount);
      self = this;
      return sender.getEntriesWithoutRelated("Accounts", ['id'], null, self.onGetResult);
    };

    DemoController.prototype.onLogin = function(sender, err) {
      var cbOnGetEntriesCount, self, sessionId;
      self = this;
      if (null !== err) {
        console.log(err);
      } else {
        sessionId = sender.sessionId;
        console.log("Session Id is " + sessionId);
        cbOnGetEntriesCount = function(sender, err, resultCount) {
          return self.onGetEntriesCount(sender, err, resultCount);
        };
        sender.getEntriesCount("Accounts", null, cbOnGetEntriesCount);
      }
	  
    };

    DemoController.prototype.run = function() {
      var cbOnLogin, client, self;
      self = this;
      cbOnLogin = function(sender, err) {
        return self.onLogin(sender, err);
      };
      client = sugarcrm.createSugarCrmClient(this.host, this.servicePath, this.username, this.password);
      client.login(cbOnLogin);
    };

    return DemoController;

  })();

  controller = new DemoController();

  controller.run();