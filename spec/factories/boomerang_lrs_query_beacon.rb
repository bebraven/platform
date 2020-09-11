FactoryBot.define do
  # Represents a Boomerang beacon sent when the page is unloaded
  # Create with: FactoryBot.json(:boomerang_lrs_query_beacon)
  factory :boomerang_lrs_query_beacon, class: Hash do
    skip_create # This isn't stored in the DB.

    # Add any variables we want to be able to set in the payload here and add them into 
    # the hash below.
    transient do
      state { 'exampleState' }
      request_url { "https://platformweb/data/xAPI/statements?agent=%7B%22objectType%22%3A%22Agent%22%2C%22mbox%22%3A%22mailto%3AJS_ACTOR_MBOX_REPLACE%22%2C%22name%22%3A%22JS_ACTOR_NAME_REPLACE%22%7D&verb=http%3A%2F%2Fadlnet.gov%2Fexpapi%2Fverbs%2Fanswered&activity=https%3A%2F%2Fbraven.instructure.com%2Fcourses%2F48%2Fassignments%2F320" }
      serialized_trace { '1;dataset=example-dataset,trace_id=example-trace-id,parent_id=example-parent-id,context=e30=' }
      duration_ms { '550' }
      javascript_controller { 'xapi.assignment' }
      event_name { 'xapi.assignment.populatePreviousAnswers' }
    end

    before(:json) do |request_msg, evaluator|
      request_msg.merge!({
        'mob.etype' => '4g',
        'mob.dl' => '10',
        'mob.rtt' => '50',
        'c.e' => 'kex9ecl6',
        'c.tti.m' => 'lt',
        'nocookie' => '1',
        'u' => evaluator.request_url,
        'r' => 'https://braven.instructure.com/',
        'v' => '1.0.0',
        'sv' => '12',
        'sm' => 'p',
        'rt.si' => 'd8495bdd-918b-464b-aa5a-4edd20fd0dac-qgglz0',
        'rt.ss' => '1599769404474',
        'rt.sl' => '2',
        'vis.st' => 'visible',
        'ua.plt' => 'MacIntel',
        'ua.vnd' => 'Google Inc.',
        'pid' => 'tc0hd88u',
        'n' => '2',
        'dom.doms' => '1',
        'mem.total' => '22257896',
        'mem.limit' => '4294705152',
        'mem.used' => '19635064',
        'mem.lsln' => '0',
        'mem.ssln' => '0',
        'mem.lssz' => '2',
        'mem.sssz' => '2',
        'scr.xy' => '1680x1050',
        'scr.bpp' => '30/30',
        'scr.orn' => '0/landscape-primary',
        'scr.dpx' => '2',
        'cpu.cnc' => '16',
        'dom.ln' => '308',
        'dom.sz' => '976088',
        'dom.ck' => '0',
        'dom.img' => '1',
        'dom.script' => '12',
        'dom.script.ext' => '10',
        'dom.iframe' => '0',
        'dom.link' => '12',
        'dom.link.css' => '10',
        'trace.serialized' => evaluator.serialized_trace,
        'state' => evaluator.state,
        'javascript.controller' => evaluator.javascript_controller,
        'name' => evaluator.event_name,
        'xapi.assignment.statement.query.activity_id' => 'https://braven.instructure.com/courses/48/assignments/320',
        'restiming' => '{"https://platformweb:3035/sockjs-node/info?t=15997694078":{"6":{"5":"52m8","6":"52m9","7":"52m9"},"73":"52mf"}}',
        'rt.start' => 'manual',
        'rt.tstart' => '1599769407788',
        'rt.nstart' => '1599769404474',
        'rt.bstart' => '1599769406591',
        'rt.blstart' => '1599769406294',
        'rt.end' => '1599769408507',
        't_done' => evaluator.duration_ms,
        'http.type' => 'f',
        'http.initiator' => 'xhr',
        'rt.tt' => '4036',
        'rt.obo' => '0',
        'nt_req_st' => '1599769407788',
        'nt_load_st' => '1599769408507',
        'nt_load_end' => '1599769408507',
        'pgu' => 'https://platformweb/course_contents/5/versions/18?state=ZTFhZTNhYjEtODEzZC00MGMxLWIzNWUtMGIyYzVmYzMwNGUzT74wIZKiqWWg-eRr0AauyJttfhcH6OftohyeamaZ4n6Hf6Qf7fCGd0Hpy2jap8NHY_I-26CA34YYzQcKBf9Zr-ks9jURiS5YMgclqN8hIyl7EKyGr_0E4__wG8PJM-uz',
        'c.tti.vr' => '3249',
        'c.lb' => 'kex9ef7p',
        'dom.res' => '9',
        'sb' => '1'
      })
    end

    initialize_with { attributes.stringify_keys }
  end
end
