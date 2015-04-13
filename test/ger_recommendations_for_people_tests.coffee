ns = global.default_namespace

describe 'crowd_weight', ->
  it 'should default do nothing', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),

        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p2','buy','x'),

        ger.event(ns, 'p3','view','a'),
        ger.event(ns, 'p3','view','b')
        ger.event(ns, 'p3','buy','y'),

        ger.event(ns, 'p4','view','a'),
        ger.event(ns, 'p4','view','b')
        ger.event(ns, 'p4','view','c')
        ger.event(ns, 'p4','buy','y'),
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', actions: {view: 1}))
      .then((recs) ->
        recs = recs.recommendations
        recs[0].thing.should.equal 'x'
        recs[1].thing.should.equal 'y'
      )

  it 'should encourage recommendations with more people recommending it', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),

        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p2','buy','x'),

        ger.event(ns, 'p3','view','a'),
        ger.event(ns, 'p3','view','b')
        ger.event(ns, 'p3','buy','y'),

        ger.event(ns, 'p4','view','a'),
        ger.event(ns, 'p4','view','b')
        ger.event(ns, 'p4','view','c')
        ger.event(ns, 'p4','buy','y'),
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', crowd_weight: 1, actions: {view: 1}))
      .then((recs) ->
        recs = recs.recommendations
        recs[0].thing.should.equal 'y'
        recs[1].thing.should.equal 'x'
      )

describe "minimum_history_required", ->
  it "should not generate recommendations for events ", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p2','view','b'),
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'view', minimum_history_required: 2, actions: {view: 1}))
      .then((recs) ->
        recs.recommendations.length.should.equal 0
        ger.recommendations_for_person(ns, 'p2', 'view', minimum_history_required: 2, actions: {view: 1})
      ).then((recs) ->
        recs.recommendations.length.should.equal 2
      )


describe "joining multiple gers", ->
  it "similar recommendations should return same confidence", ->
    ns1 = 'ger_1'
    ns2 = 'ger_2'
    bb.all([
      init_ger(default_esm, ns1),
      init_ger(default_esm, ns2)
    ])
    .spread (ger1, ger2) ->
      bb.all([

        ger1.event(ns1, 'p1','view','a'),
        ger1.event(ns1, 'p2','view','a'),
        ger1.event(ns1, 'p2','buy','b'),

        ger2.event(ns2, 'p1','view','a'),
        ger2.event(ns2, 'p2','view','a'),
        ger2.event(ns2, 'p2','buy','b'),
      ])
      .then( -> bb.all([
          ger1.recommendations_for_person(ns1, 'p1', 'buy', {similar_people_limit: 2, history_search_size: 4, actions: {view: 1}}),
          ger2.recommendations_for_person(ns2, 'p1', 'buy', {similar_people_limit: 4, history_search_size: 8, actions: {view: 1}})
        ])
      )
      .spread((recs1, recs2) ->
        recs1.confidence.should.equal recs2.confidence
      )


describe "confidence", ->

  it 'should return a confidence ', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','action1','a'),
        ger.event(ns, 'p2','action1','a'),
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'action1', actions: {action1: 1}))
      .then((similar_people) ->
        similar_people.confidence.should.exist
      )

  it 'should return a confidence of 0 not NaN', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','action1','a')
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'action1', actions: {action1: 1}))
      .then((similar_people) ->
        similar_people.confidence.should.equal 0
      )

  it "higher weighted recommendations should return greater confidence", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p1','view','b'),
        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p2','view','b'),
        ger.event(ns, 'p2','view','c'),

        ger.event(ns, 'p3','view','x'),
        ger.event(ns, 'p3','view','y'),
        ger.event(ns, 'p4','view','x'),
        ger.event(ns, 'p4','view','z'),
      ])
      .then(->
        bb.all([
          ger.recommendations_for_person(ns, 'p1', 'view', actions: {view: 1})
          ger.recommendations_for_person(ns, 'p3', 'view', actions: {view: 1})
        ])
      )
      .spread((recs1, recs2) ->
        recs1.confidence.should.greaterThan recs2.confidence
      )

  it "more similar people should return greater confidence", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p2','view','a'),

        ger.event(ns, 'p3','view','b'),
        ger.event(ns, 'p4','view','b'),
        ger.event(ns, 'p5','view','b'),
      ])
      .then(->
        bb.all([
          ger.recommendations_for_person(ns, 'p1', 'view', actions: {view: 1})
          ger.recommendations_for_person(ns, 'p3', 'view', actions: {view: 1})
        ])
      )
      .spread((recs1, recs2) ->

        recs2.confidence.should.greaterThan recs1.confidence
      )

  it "longer history should mean more confidence", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p2','view','a'),

        ger.event(ns, 'p3','view','x'),
        ger.event(ns, 'p3','view','b'),
        ger.event(ns, 'p4','view','x'),
        ger.event(ns, 'p4','view','b'),
      ])
      .then(->
        bb.all([
          ger.recommendations_for_person(ns, 'p1', 'view', actions: {view: 1})
          ger.recommendations_for_person(ns, 'p3', 'view', actions: {view: 1})
        ])
      )
      .spread((recs1, recs2) ->

        recs2.confidence.should.greaterThan recs1.confidence
      )

  it "should not return NaN as conifdence", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', actions: {view: 1}))
      .then((recs) ->
        recs.confidence.should.equal 0
      )

describe "weights", ->
  it "weights should determine the order of the recommendations", ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p1','buy','b'),

        ger.event(ns, 'p6','buy','b'),
        ger.event(ns, 'p6','buy','x'),

        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p3','view','a'),
        ger.event(ns, 'p4','view','a'),
        ger.event(ns, 'p5','view','a')

        ger.event(ns, 'p2','buy','y'),
        ger.event(ns, 'p3','buy','y'),
        ger.event(ns, 'p4','buy','y'),
        ger.event(ns, 'p5','buy','y')
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', actions: {view: 1, buy: 5}))
      .then((recs) ->
        item_weights = recs.recommendations
        #p1 is similar by 1 view to p2 p3 p4 p5
        #p1 is similar to p6 by 1 buy
        #because a buy is worth 5 views x should be recommended before y
        item_weights[0].thing.should.equal 'b'
        item_weights[1].thing.should.equal 'y'
        item_weights[2].thing.should.equal 'x'

      )
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', actions: {view: 1, buy: 10}))
      .then((recs) ->
        item_weights = recs.recommendations
        item_weights[0].thing.should.equal 'b'
        item_weights[1].thing.should.equal 'x'
        item_weights[2].thing.should.equal 'y'
      )

  it 'should not use actions with 0 or negative weights', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','action1','a'),
        ger.event(ns, 'p2','action1','a'),
        ger.event(ns, 'p2','buy','x'),

        ger.event(ns, 'p1','neg_action','a'),
        ger.event(ns, 'p3','neg_action','a'),
        ger.event(ns, 'p3','buy','y'),

      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', actions: {action1: 1, neg_action: 0}))
      .then((recs) ->
        item_weights = recs.recommendations
        item_weights.length.should.equal 1
        item_weights[0].thing.should.equal 'x'
      )

describe "person exploits,", ->
  it 'related_things_limit should stop one persons recommendations eliminating the other recommendations', ->
    init_ger()
    .then (ger) ->
      bb.all([
        ger.event(ns, 'p1','view','a'),
        ger.event(ns, 'p1','view','b'),
        #p2 is closer to p1, but theie recommendation was 2 days ago. It should still be included
        ger.event(ns, 'p2','view','a'),
        ger.event(ns, 'p2','view','b'),
        ger.event(ns, 'p2','buy','x', created_at: moment().subtract(2, 'days').toDate()),

        ger.event(ns, 'p3','view','a'),
        ger.event(ns, 'p3','buy','l', created_at: moment().subtract(3, 'hours').toDate()),
        ger.event(ns, 'p3','buy','m', created_at: moment().subtract(2, 'hours').toDate()),
        ger.event(ns, 'p3','buy','n', created_at: moment().subtract(1, 'hours').toDate())
      ])
      .then(-> ger.recommendations_for_person(ns, 'p1', 'buy', related_things_limit: 1, actions: {buy: 5, view: 1}))
      .then((recs) ->
        item_weights = recs.recommendations
        item_weights.length.should.equal 2
        item_weights[0].thing.should.equal 'x'
        item_weights[1].thing.should.equal 'n'

      )


  it "a single persons mass interaction should not outweigh 'real' interations", ->
    init_ger()
    .then (ger) ->
      rs = new Readable();
      for x in [1..100]
        rs.push("bad_person,view,t1,#{new Date().toISOString()},\n");
        rs.push("bad_person,buy,t1,#{new Date().toISOString()},\n");
      rs.push(null);
      ger.bootstrap(ns,rs)
      .then( ->
        bb.all([
          ger.event(ns, 'real_person', 'view', 't2')
          ger.event(ns, 'real_person', 'buy', 't2')
          ger.event(ns, 'person', 'view', 't1')
          ger.event(ns, 'person', 'view', 't2')
        ])
      )
      .then( ->
        ger.recommendations_for_person(ns, 'person', 'buy', actions: {buy:1, view:1})
      )
      .then((recs) ->
        item_weights = recs.recommendations
        temp = {}
        (temp[tw.thing] = tw.weight for tw in item_weights)
        temp['t1'].should.equal temp['t2']
      )
