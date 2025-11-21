return A.e(A.r5(A.c5("https://montajati-official-backend-production.up.railway.app/api/waseet-statuses/approved",0,null),A.D(["Content-Type","application/json"],k,k)),$async$EE)
k=A.c5("https://montajati-official-backend-production.up.railway.app/api/fcm/update-last-used",0,null)
switch(a){case"updateLastUsed":b=A.D(["lastUsed",c],k,k)
return A.e(A.r5(k,A.D(["Content-Type","application/json"],b,b)),$async$EE)
break}j=A.c5("https://montajati-official-backend-production.up.railway.app/api/fcm/update-token",0,null)
switch(a){case"updateToken":b=A.D(["token",c],j,j)
return A.e(A.r5(j,A.D(["Content-Type","application/json"],b,b)),$async$EE)
break}return null