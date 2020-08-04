FactoryBot.define do
  factory :lti_advantage_access_token, class: Hash do

    access_token { 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2NhbnZhcy5pbnN0cnVjdHVyZS5jb20iLCJzdWIiOiIxNjAwNTAwMDAwMDAwMDAwMTIiLCJhdWQiOiJodHRwczovL2JyYXZlbi5pbnN0cnVjdHVyZS5jb20vbG9naW4vb2F1dGgyL3Rva2VuIiwiaWF0IjoxNTk1NTMxNTMwLCJleHAiOjE1OTU1MzUxMzAsImp0aSI6ImQwZTYzNTRhLWNiMWMtNGVjZC04ODg2LWZkOWViNzI1OGMyMiIsInNjb3BlcyI6Imh0dHBzOi8vcHVybC5pbXNnbG9iYWwub3JnL3NwZWMvbHRpLWFncy9zY29wZS9saW5laXRlbSBodHRwczovL3B1cmwuaW1zZ2xvYmFsLm9yZy9zcGVjL2x0aS1hZ3Mvc2NvcGUvbGluZWl0ZW0ucmVhZG9ubHkifQ.CNVRit5ee1Rt1lICh2u4AbKRALWpOrnzxFSKTl4ofKI' } 
    token_type { 'Bearer' }
    expires_in { '3600' }
    scope { 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly https://purl.imsglobal.org/spec/lti-ags/scope/score' }

    initialize_with { attributes.stringify_keys }
  end
end
