<form action='/login' id='login_form' method='POST'>
  <div id='form_testname'>
    <label for='login_field'>Testname</label>
    <input id='login_field' name='testname' type='text'>
  </div>
  <div id='form_password'>
    <label for='password_field'>Password</label>
    <input id='password_field' name='password' type='password'>
  </div>
  <div id='form_submit'>
    <input type='submit' value='login'>
    <input id='redirect' name='redirect' type='hidden' value=''>
  </div>
</form>
<script>
  document.getElementById('redirect').value = window.location
</script>
