Point centerOfBall(Point A, Point B, Point C, float r) {
  Point circumcenter = circumcircleCenter(A, B, C);
  Vector normal = U(N(V(A,C), V(C, B)));
  
  float dACircumcenter = d(A, circumcenter);
  
  if (r < dACircumcenter)
    return null;
  
  float distance = sqrt(r*r - dACircumcenter*dACircumcenter);
  Point center = P(circumcenter, distance, normal);
  
  return center;
}

float angle(Vector U, Vector V, Vector W) {
  float a = atan2(d(V,U(N(W,U))),d(V,U(U))); 
  
  if(a<0) 
    a+=TWO_PI; 
    
  return a; 
}

void drawBallCenter(Edge pivotEdge, int pivotVertex, List<Point> P, float r, color c) {
  Point A = P.get(pivotVertex);
  Point B = P.get(pivotEdge.first);
  Point C = P.get(pivotEdge.second);
  
  Point centr = centerOfBall(A, B, C, r);
  
  fill(c);
  show(centr, 0.1);
  
  //beginShape();
  //v(B);
  //v(A);
  //v(C);
  //endShape(CLOSE);
  
  strokeWeight(1);
  stroke(c, 100);
  noFill();
  //fill(c, 50);
  show(centr, r);
}

void drawNormal(List<Point> P, Edge e, int vertex, float r) {
  int e1 = e.first, e2 = e.second;
  Point 
    E1 = P.get(e1),
    E2 = P.get(e2),
    V = P.get(vertex);
    
  Point ballCenter = centerOfBall(E1, E2, V, r);
  
  strokeWeight(0);
  fill(yellow);
  beam(P(E1,E2), ballCenter, 0.2);
    
  //VS x SF
}

void addSeedEdges(List<Point> P, float r){
  for (int i = 50; i<P.size(); i++){
    for (int j = i+1; j<P.size(); j++){
      for (int k = j+1; k<P.size(); k++){
        Point I = P.get(i);
        Point J = P.get(j);
        Point K = P.get(k);
        Point sphereCenter = centerOfBall(J, I, K, r);
        
        if(sphereCenter == null){
          continue;
        }
        
        boolean isValid = true;
        
        for (int l = 0; l<P.size(); l++){
          if( l== i || l==j || l==k ){
            continue;
          }
          if(d(P.get(l), sphereCenter) < r){
            isValid = false;
            break;
          }
        }
        
        if (isValid){
          Edge e1 = new Edge(j, i),
               e2 = new Edge(k, j),
               e3 = new Edge(i, k);
               
          pivotEdges.put(e1, k);
          pivotEdges.put(e2, i);
          pivotEdges.put(e3, j);
          frontier.add(e1);
          frontier.add(e2);
          frontier.add(e3);
          generatedTriangles.add(new Triangle(i, j, k));
          return;
        }
      }
    }
  }
  throw new RuntimeException("No seed triangle found. Better luck next time.");
}

void ballPivot(List<Point> P, float r, int limit){
  addSeedEdges(P, r);
  //println("Added seed edges: ", frontier);
  
  int count = 0;
  
  while (!frontier.isEmpty() && count < limit) {
    //println(frontier);
    
    // Get the next item from the frontier
    Edge pivotEdge = frontier.pop();
    int pivotVertex = pivotEdges.remove(pivotEdge);
    
    // Add the frontier to explored
    explored.add(pivotEdge);
    count++;
    
    //drawNormal(P, pivotEdge, pivotVertex, r);
    int nextVertex = ballPivot(pivotEdge, pivotVertex, P, r);    
    
    //if (count == limit) {
    //  drawBallCenter(pivotVertex, pivotEdge.first, pivotEdge.second, r, blue);
    //}
    
    if (nextVertex < 0) {
      println("Could not find vertex;", pivotEdge, "is boundary");
      boundaryEdges.add(pivotEdge);
      continue;
    }
    
    // Create the next edges
    Edge edgeFirst = new Edge(pivotEdge.first, nextVertex);
    Edge edgeSecond = new Edge(nextVertex, pivotEdge.second);
    
    // If both have not  been seen, add a triangle
    boolean exploredEdgeFirst = false, exploredEdgeSecond = false;
    if (explored.contains(edgeFirst)) {
      exploredEdgeFirst = true;
    }
    if (!frontier.contains(edgeFirst) && !exploredEdgeFirst) {
      // This edge was not seen, so add it to the frontier
      pivotEdges.put(edgeFirst, pivotEdge.second);
      frontier.add(edgeFirst);
    }
    
    if (explored.contains(edgeSecond)) {
      exploredEdgeSecond = true;
    }
    if (!frontier.contains(edgeSecond) && !exploredEdgeSecond) {
      // This edge was not seen, so add it to the frontier
      pivotEdges.put(edgeSecond, pivotEdge.first);
      frontier.add(edgeSecond);
    }
    
    if (!exploredEdgeFirst && !exploredEdgeSecond) {
      // Neither edge was found, so this is a new triangle
      generatedTriangles.add(new Triangle(pivotEdge.first, pivotEdge.second, nextVertex));
      
      // Peek at the ball that will pivot around the next triangle
      Edge nextPivotEdge = frontier.peek();
      int nextPivotVertex = pivotEdges.get(nextPivotEdge);
      
      if (count == limit)
        drawBallCenter(nextPivotEdge, nextPivotVertex, P, r, blue);
    }
  }
  
  //println("Done");
}

int ballPivot(Edge pivotEdge, int pivotVertex, List<Point> P, float r) {
  float bestAngle = Float.MAX_VALUE;
  int bestPointIndex = -30;
  
  // AB
  for (int targetIndex = 0; targetIndex < P.size(); targetIndex++) {
    
    if (pivotEdge.first == targetIndex || pivotEdge.second == targetIndex || pivotVertex == targetIndex)
      continue;  
      
    float angle = pivotAngle(pivotEdge, pivotVertex, targetIndex, P, r);
    if (angle < bestAngle) {
      bestAngle = angle;
      bestPointIndex = targetIndex;
    }
  }
     
  return bestPointIndex;
}

float pivotAngle(Edge edge, int sourceVertex, int targetVertex, List<Point> P, float r) {
  Point A = P.get(sourceVertex),
        B = P.get(edge.first),
        C = P.get(edge.second),
        D = P.get(targetVertex);
        
  Point centerABC = centerOfBall(A, B, C, r);
  Point centerCBD = centerOfBall(C, B, D, r);
  
  if (centerABC == null || centerCBD == null) 
    return Float.MAX_VALUE;
  
  Point mBC = P(B,C);
  
  Vector U = V(mBC, centerABC);
  Vector V = V(mBC, centerCBD);
  Vector W = V(C, B);
  
  return angle(U, V, W);
}