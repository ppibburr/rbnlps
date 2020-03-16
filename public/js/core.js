  function speak(txt, after) {
    fetch('/spoke', {
      method: 'post',
      body: txt
    }).then(function(response) {
      return response.json();
    }).then(function(data) {
      console.log(data);
      after(data);
    });
  }        
  
  function slide(id,a,c) {
	  speak(a.replace("%lvl",''+id.value), function() {
		  
	  });
  }
  
  function toggle(id,a,c) {
    speak(a, function() {
      speak('status of '+id.dataset.name, function(j) {
        //document.getElementById(id.id).innerText = j['status'];
        _x = j['state'][id.dataset.field];
        console.log({x: _x});
        set_active(id,_x);
      })
    });
  }
  
  function set_active(id,_x) {
        if (_x) {
          id.classList.add('active');
        } else {
          id.classList.remove('active');
        }	  
  }
  
  function update() {
	  id=document.querySelector('.rbnlps-skill');
	  updates=[id.querySelectorAll('.toggle'),
	  id.querySelectorAll('.state-value'),
	  id.querySelectorAll('.slider')]
	  
	  speak("status of "+id.dataset.name, function(j) {
		 console.log('tick');

		 updates[0].forEach(function(e) {
			console.log(e);
			ss=(j['state'][e.dataset.field]);
			set_active(e,ss);
		 });
		 
		 updates[1].forEach(function(e) {
			console.log(e);
			ss=(j['state'][e.dataset.field]);
			e.innerText = e.dataset.field+': '+ss; 
		 });
		 
		 updates[2].forEach(function(e) {
			console.log(e);
			e.value = j['state'][e.dataset.field]; 
		 }); 
	  });
  }

  window.setInterval(function() {
	update();  
  }, 2000);
