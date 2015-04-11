<form action='/login' method='POST'>
  <div id='login_name'>
    <label>Login</label>
    <input id='login' name='login' type='text'>
  </div>
  <div id='login_password'>
    <label>Password</label>
    <input id='password' name='password' type='password'>
  </div>
  <div id='login_submit'>
    <input type='submit' value='login'>
    <input id='redirect' name='redirect' type='hidden' value=''>
  </div>
</form>
<script>
  document.getElementById('redirect').value = window.location
</script>
