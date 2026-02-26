## How to get from Ax to Bx

One comment we sometimes get when we publish measures that look at distances, such as the distance students travel to school, is that most people don’t have wings so “crow-flies” distance doesn’t really represent reality. While this is true, crow-flies distance can be calculated with a simple application of basic trigonometry<sup>[1](#fft-note-1 "foot note")</sup>; finding real-world travel distances is far more computationally intensive.

The real issue is in finding the best route to take to complete the journey, which doesn’t sound too bad at first; online route-planners to do it all the time. Unlike a standard route-planner, however, we’re not trying to find a route for just one journey; we’ve got to find millions. This alone has made real world distances impractical.

Until recently: we’ve cracked that code.

This post is going to be a little more technical than our usual fare, but for those with an interest (or a masochistic streak), this is at least one way we’ve found to go everywhere at once.

## Data

As is often the case at Datalab, we start with data, in this case the Open Street Map (OSM). OSM is a crowdsourced mapping dataset of which we use just a portion, covering England, Wales and Scotland<sup>[2](#fft-note-2 "foot note")</sup>. It contains three fundamental components: nodes, ways and relations. Nodes are map positions. Ways are used to describe lines, such as roads, boundaries and coastlines, and are constructed of ordered sequences of nodes. Relations group other things together and can be required for example where the number of nodes of a single conceptual “way” exceeds some recommended maximum (or hard limit). It also includes “tags” for each of the other fundamental types, providing key-value pairs of free-form data associated with these map features.

We parse the source data files (they are provided as XML) and load them into an SQL database to create a working dataset that contains ways that represent traversable routes and the nodes, relations and tags that relate to these ways. While creating this working dataset, we also reproject the nodes’ longitude and latitude onto Ordinance Survey grid references (easting and northing)<sup>[3](#fft-note-3 "foot note")</sup>.

## Network Graph

Apologies if you were expecting to see some pretty charts: in computer science, a graph is an abstract data structure made up of “vertices” and the “edges” (connections) between them. This sort of data structure will probably sound familiar from the discussion of the OSM dataset.

We construct a full network graph from the working dataset. The graph’s vertices are significant nodes, such as those at dead-ends or the junctions of paths and roads. Its edges connect vertices with availability of and distance<sup>[4](#fft-note-4 "foot note")</sup> by each traversal method of interest (footpath, road and public transport; these uses have to be parsed from the way and relation tags), based on OSM’s ways. When we originally constructed this graph, we used unidirectional edges for performance reasons, but this also allows us to account for features of the road network, such as one-way streets.

With this graph constructed we can use an implementation of the A* (A-star) algorithm<sup>[5](#fft-note-5 "foot note")</sup> to find shortest path, and hence the distance, between any two points, with the edges’ distances as weights. Assuming you have some pretty serious hardware (maybe a data centre) or you don’t mind waiting (months or years rather than days).

Even if you do some graph reduction, since the level of detail in OSM data is high, and collapse vertices together where the edge between them is at most a few metres, the full network graph is large and the performance (and space required) is roughly exponential with the distance between the points<sup>[6](#fft-note-6 "foot note")</sup>. If you try to calculate too many journeys at once, or (worse yet) use a more simplistic breadth-first full network traversal, the storage requirements for book-keeping also prove prohibitive.

## The Journey Graph

We spent some time trying to improve our implementation of the path finding algorithm so that it was fast enough for practical use with millions of journeys, such as experimenting with different approaches to batching, different heuristics for A*, and using hints for prioritising (or eliminating) branches that needed to be tested. Eventually we came to the conclusion that a different approach would be required; the full graph was just too big.

In hindsight, it seems pretty obvious.

For a given set of distinct journeys (if multiple students have the same journey, we need calculate it only once) that need to have distances calculated, we first generate a custom “journey graph”. Initially this is a copy of the full graph, with the vertices at either end of any journey flagged as critical. We then reduce the size and complexity of this journey graph.

Non-critical vertices are selected for removal based on their branching (the number of edges connected to them). In order to make it easier to discuss, we’ll assume for a moment that we are using a bidirectional graph (so that we have only one edge between any two vertices, rather than one in each direction):
-	edges that start and end at the same vertex can be pruned (discarded);
-	vertices with only one edge can be pruned, along with that edge;
-	vertices with two edges are “pass-through” vertices; they can be removed and the two edges combined into one;
-	vertices with three or more edges can be removed if we add edges between the connected vertices.

This process can be repeated until the graph is “small enough”<sup>[7](#fft-note-7 "foot note")</sup>.

During this process, the “new” edges produced often already exist in the dataset (having been created via a different route); we simply keep one edge and use it to record the shortest route by each method (footpath, road and public transport).

## Path finding

Finally, we perform a breadth-first traversal of the entire journey graph starting at every vertex that is the beginning of at least one journey. Put simply, we take each origin vertex, one at a time, and find the distance to everywhere else.

There is nothing clever about this process. Initially we add the origin to the “visited” set. In each subsequent step, we add to this set all the vertices that can be reached (and the total traversed distance for each method) from anything added (or updated) in the previous iteration. Since there can be multiple routes to reach a single vertex, we update those where a subsequent step found a shorter path (or a method that wasn’t possible by other routes). We put a limit on the journey length, however, to ensure that we don’t calculate distances for journeys that it isn’t plausible people would take (students aren’t likely to travel more than 100km to school, at least in this country!).

While this might seem a rather brute force approach, there is some reasoning behind it. First, our worst-case use cases often involve many journeys from each origin, for example, finding the distance to every sixth form or college students in a post-16 cohort might plausibly choose to attend. Apart from that, this brute force approach means that we do not have to prioritise vertices to visit using a calculated heuristic<sup>[8](#fft-note-8 "foot note")</sup>, the calculation and ordering of which proved to take a significant proportion of the computational effect, during testing.

## Going the distance

Finally, we have calculated three distances for all the journeys we need, by foot, road and public transport. We could simply read off the shortest, but people don’t tend to like walking very far so we discount routes that require walking more than 4km and add a “cost” to walking so that, if it is only slightly shorter than travelling by another method, that will be preferred.
The remaining change we made, including the journey graph calculation, was to allow some walking in the other methods:
-	it has to be possible to start and end all journeys on foot, since you can’t just jump in a car on the motorway, for example;
-	road travel can include walking a short distance at the beginning and end, if the closest vertex to the origin and/or destination can not be reached by road;
-	the public transport route can include some walking at the beginning and end of the journey, but also within the journey, for example to change platforms at a train station or move between bus and train.

All these sections of walking are tracked and recorded so that we can use this “cost” in determining the route to use. As a result, it is not necessarily the shortest route, but the one we think people are most likely to actually take.

## Notes

1. <a name="fft-note-1"></a>Like most small countries, in Britain we can ignore the curvature of the Earth so use a two-dimensional planar map projection as standard (easting and northing), rather than having to resort to polar coordinates (longitude and latitude).
2. <a name="fft-note-2"></a>At Datalab, most of our work focusses on England or England and Wales, but journeys may cross the borders between the three nations so we include some of Scotland as well.
3. <a name="fft-note-3"></a>In fact, this involves two reprojections; one, between differing ellipsoid projections, and a second, onto a plain. For details on map projections and translating between them, see the information provided by Ordinance Survey [here](https://docs.os.uk/more-than-maps/a-guide-to-coordinate-systems-in-great-britain/transverse-mercator-map-projections "Transverse Mercator Map Projections").
4. <a name="fft-note-4"></a>Distance here is calculated as the sum of the straight-line distance between consecutive nodes within each way.
5. <a name="fft-note-5"></a>For more information, see the [Wikipedia page](https://en.wikipedia.org/wiki/A*_search_algorithm "A* search algorithm") on A*.
6. <a name="fft-note-6"></a>A* has worst-case performance and space complexity of O(b<sup>d</sup>), where b is the branching factor (how many edges connect from each vertex) and d the “depth” or number of edges between the start and end points.
7. <a name="fft-note-7"></a>How small this is will depend on usage, but we have managed to remove more than 95% of vertices in some cases.
8. <a name="fft-note-8"></a>This is used, for example, in the A* path finding algorithm.
