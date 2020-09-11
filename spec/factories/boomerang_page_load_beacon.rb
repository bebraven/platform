FactoryBot.define do
  # Represents a Boomerang beacon sent when the page is unloaded
  # Create with: FactoryBot.json(:boomerang_page_load_beacon)
  factory :boomerang_page_load_beacon, class: Hash do
    skip_create # This isn't stored in the DB.

    # Add any variables we want to be able to set in the payload here and add them into 
    # the hash below.
    transient do
      state { 'exampleState' }
      request_url { "https://platformweb/course_contents/5/versions/18?state=#{state}" }
      serialized_trace { '1;dataset=development,trace_id=0df2e17d-4991-4421-b021-3706502bc992,parent_id=1452b9b9-aebf-43e0-9a1a-9cf1f10f8131,context=e30=' }
      duration_ms { '2000' }
    end

    before(:json) do |request_msg, evaluator|
      request_msg.merge!({
        'mob.etype' => '4g',
        'mob.dl' => '10',
        'mob.rtt' => '50',
        'c.e' => 'keycaw6h',
        'c.tti.m' => 'lt',
        'nocookie' => '1',
        'rt.start' => 'navigation',
        'rt.bmr' => '1714,398',
        'rt.tstart' => '1599834748265',
        'rt.bstart' => '1599834750388',
        'rt.blstart' => '1599834749979',
        'rt.end' => '1599834751565',
        't_resp' => '1546',
        't_page' => '1754',
        't_done' => evaluator.duration_ms,
        't_other' => 't_domloaded|3230,boomerang|8,boomr_fb|2123,boomr_ld|1714,boomr_lat|409',
        'rt.tt' => '3300',
        'rt.obo' => '0',
        'nt_nav_st' => '1599834748265',
        'nt_red_st' => '1599834748268',
        'nt_red_end' => '1599834748444',
        'nt_fet_st' => '1599834748444',
        'nt_dns_st' => '1599834748444',
        'nt_dns_end' => '1599834748444',
        'nt_con_st' => '1599834748444',
        'nt_con_end' => '1599834748444',
        'nt_req_st' => '1599834748446',
        'nt_res_st' => '1599834749811',
        'nt_res_end' => '1599834749811',
        'nt_domloading' => '1599834749820',
        'nt_domint' => '1599834751461',
        'nt_domcontloaded_st' => '1599834751461',
        'nt_domcontloaded_end' => '1599834751495',
        'nt_domcomp' => '1599834751564',
        'nt_load_st' => '1599834751564',
        'nt_load_end' => '1599834751564',
        'nt_ssl_st' => '1599834748444',
        'nt_enc_size' => '26344',
        'nt_dec_size' => '26344',
        'nt_trn_size' => '28603',
        'nt_protocol' => 'h2',
        'nt_spdy' => '1',
        'nt_cinf' => 'h2',
        'nt_first_paint' => '1599834751426',
        'nt_red_cnt' => '1',
        'nt_nav_type' => '0',
        'restiming' => '{"https://":{"p":{"latformweb":{"/":{"course_contents/5/versions/18?state=exampleState":"6,16z,16y,51,50,50,50,50,50,50,4*1kbs,1qr","__rack/":{"swfobject.js":"317h,e,e,8*17vw,2k*20","web_socket.js":"317h,t,t,h*19uq,2k*20"},"packs/":{"boomerang-067bbe544ab8d9133aec.js":"317h,2v,2i,j*128d1,9w,74lo*20","application-067bbe544ab8d9133aec.js":"317j,6p,4q,i*156x2,eg,kt9c*20","sidebar-067bbe544ab8d9133aec.js":"317j,9w,6o,k*1981l,kw,y4ml*20","content_editor-067bbe544ab8d9133aec.js":"317k,k2,5r,j*117wfu,21o,5x98l*20","project_submit_button-067bbe544ab8d9133aec.js":"317k,b2,6l,j*1a6mx,me,17let*20","xapi_assignment-067bbe544ab8d9133aec.js":"317k,gq,fj,f8*1462t,d5,fgrl*24"},"assets/":{"s":{"caffolds.self-115b22b3993b8ef9b3115288b9b7cc78d289c1fdae626e8d09d717117386a99d.css?body=1":"217i,4a,4a,h*1uv,gr*44","tyle.self-396761af43ca5299bab0dc8781cef0d392175dfe962070fd3f5c21ce9e8324cd.css?body=1":"217i,2i,2h,g*12oh,gy*44"},"home.self-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.css?body=1":"217h,1x,1x,h*1,gd*44","industries.self-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.css?body=1":"217i,37,37,g*1,gi*44","reboot.self-2dee2ad0d67b17717fa12badfa1246828a4659415f23d020a79d872d1dc89637.css?body=1":"217i,3g,3a,g*13qr,hl*44","application.self-89f69c0a5e270e4ece7c29778d98efdbb91eabe9f8c7c7288cf6fcf0e77dca79.css?body=1":"217i,65,64,i*146g,gu*44","co":{"urse_content":{"s.self-7c674d5bade96941e8ea2523e425eba109948f48a0b7e66eae3ff6ae18427b92.css?body=1":"217j,4q,4e,h*15ajj,pe*44","_histories.self-de2252966ab54a4348a6f59e0b4063a67634ce8d230c87e065dd0f03d9b1baf9.css?body=1":"217j,5b,5a,i*11e5,h5*44"},"ntent_editor.self-918faf4f08dce7d242c67ad6a5877cd705c5ad8f386e99bce8591a5401b2118a.css?body=1":"217j,61,61,k*1iv,gx*44"},"TradeGothicNo.20-CondBold_gdi-d061b91d87d877f44950d61e59fb1e93201b55010afc14a0cdc8057827c82421.woff":"42hr,o,n,e*1fs0,44"}},":3035/sockjs-node/info?t=15998347":{"50":{"160":"51gn","260":"51jg"},"49983":"51br"}},"ortal.bebraven.org//courses/1/files/39902/preview":"*015,5z,1vj,fv|11ry,3h"},"s3.amazonaws.com/canvas-stag-assets/braven_newui.css?v=":"217j,7k*44","fonts.googleapis.com/css?family=News+Cycle:400,700&display=swap":"41fd,12,12,d*1bu,2m,zk"}}',
        'u' => evaluator.request_url,
        'r' => 'https://braven.instructure.com/',
        'v' => '1.0.0',
        'sv' => '12',
        'sm' => 'p',
        'rt.si' => '14736edd-5f2a-462f-a9e4-a97f49076f70-qgi0e4',
        'rt.ss' => '1599834748265',
        'rt.sl' => '1',
        'vis.st' => 'visible',
        'ua.plt' => 'MacIntel',
        'ua.vnd' => 'Google Inc.',
        'pid' => 'vcw5scr2',
        'n' => '1',
        'c.t.longtask' => '0*b*03',
        'c.t.fps' => '0*a*0115',
        'c.tti.vr' => '3231',
        'c.lt.n' => '3',
        'c.lt.tt' => '911.1249999841675',
        'c.lt' => "~(~(a~(~(a~0~s~'~t~0))~d~'eb~n~1~s~'1sc)~(a~(~(a~0~s~'~t~0))~d~'8u~n~1~s~'26m)~(a~(~(a~0~s~'~t~0))~d~'28~n~1~s~'2fm))",
        'c.f' => '5',
        'c.f.d' => '1288',
        'c.f.m' => '1',
        'c.f.l' => '3',
        'c.f.s' => 'keycaxti',
        'dom.res' => '29',
        'dom.doms' => '5',
        'mem.total' => '22284788',
        'mem.limit' => '4294705152',
        'mem.used' => '19658720',
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
        'sb' => '1'
      })
    end

    initialize_with { attributes.stringify_keys }
  end
end
