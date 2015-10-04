var app = angular.module('app');

app.controller('studentsCtrl', function($scope, mainFactory, $window, $state) {
  mainFactory.getAllStudents(function(result) {
    $scope.students = result;
  });

  mainFactory.getAllActivities(function(result) {
  	$scope.activities = result;
  });

  $scope.filter = {
  	date: new Date(2015, 9, 4)
  }

  $scope.searchByActivityAndDate = function(filter) {
  	date = new Date(filter["date"]).toISOString().slice(0,10);
  	mainFactory.searchByActivityAndDate(filter["activityId"], date, function(result) {
      $scope.students = result;
      console.log(result);
    });
  }

  var studentsToCheckIn = {};
  $scope.checkin = function(status, studentID) {
	if (studentsToCheckIn[studentID]) {
		studentsToCheckIn[studentID]["status"] = status;
	} else {
		studentsToCheckIn[studentID] = {"status": status};
	}	
  }

  $scope.addComment = function(comment, studentID) {
  	if (studentsToCheckIn[studentID]) {
		studentsToCheckIn[studentID]["comment"] = comment;
	} else {
		studentsToCheckIn[studentID] = {"comment": comment};
	}
  	console.log(studentsToCheckIn);
  }

  function getToday() {
	  var today = new Date();
	  var dd = today.getDate();
	  var mm = today.getMonth()+1; //January is 0!
	  var yyyy = today.getFullYear();

	  if(dd<10) {
	    dd= '0' + dd;
	  } 

	  if(mm<10) {
	    mm = '0' + mm;
	  } 

	  today = yyyy + '-' + mm + '-' + dd;
	  return today;
  }

  $scope.finalCheckIn = function() {
	mainFactory.checkIn(1, studentsToCheckIn, getToday(), function(result) {
		console.log('checked in');
	})
  }
});
