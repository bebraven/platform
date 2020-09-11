FactoryBot.define do
  # Represents a Boomerang beacon sent when the page is unloaded
  # Create with: FactoryBot.json(:boomerang_page_unload_beacon)
  factory :boomerang_page_unload_beacon, class: Hash do
    skip_create # This isn't stored in the DB.

    # Add any variables we want to be able to set in the payload here and add them into 
    # the hash below.
    transient do
      state { 'exampleState' }
      request_url { "https://platformweb/course_contents/5/versions/18?state=#{state}" }
      serialized_trace { '1;dataset=development,trace_id=0df2e17d-4991-4421-b021-3706502bc992,parent_id=1452b9b9-aebf-43e0-9a1a-9cf1f10f8131,context=e30=' }
      duration_ms { '2000' }
      referrer { 'https://braven.instructure.com/' }
    end

    before(:json) do |request_msg, evaluator|
      request_msg.merge!({
        'mob.etype' => '4g',
        'mob.dl' => '10',
        'mob.rtt' => '50',
        'c.e' => 'kex0ihsf',
        'c.tti.m' => 'lt',
        'nocookie' => '1',
        'r' => evaluator.referrer,
        'v' => '1.0.0',
        'sv' => '12',
        'sm' => 'p',
        'rt.si' => '90fa6442-c556-4641-8166-6f474f7bb25c-qggagh',
        'rt.ss' => '1599754481295',
        'rt.sl' => '2',
        'vis.st' => 'visible',
        'ua.plt' => 'MacIntel',
        'ua.vnd' => 'Google Inc.',
        'pid' => 'reun6quk',
        'n' => '3',
        'dom.doms' => '1',
        'mem.total' => '16244595',
        'mem.limit' => '4294705152',
        'mem.used' => '13967607',
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
        'rt.tstart' => '1599754481295',
        'rt.bstart' => '1599754483994',
        'rt.blstart' => '1599754483770',
        'rt.end' => '1599754485191',
        't_done'=> evaluator.duration_ms,
        'rt.tt' => '4996',
        'rt.obo' => '0',
        'rt.quit' => '',
        'u'=> evaluator.request_url,
        'c.tti.vr' => '3815',
        'c.lb' => 'kex0imgb',
        'dom.res' => '22',
        'sb' => '1'
      })
    end

    initialize_with { attributes.stringify_keys }
  end
end
