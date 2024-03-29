using DataStructures # -> definir una cola de prioridad

#######################################################
#
# Funcionamiento de algoritmos de caminos mínimos
#
######################################################

type grafoCaminos
    vertices::Int64
    longitud::Array{Int64,2} #arco[i,j] indica la longitud
end

function generarGrafoCaminos(n::Int64,maxLongitud::Int64)
  a=Array{Int64}(n,n)
  rand!(a,1:maxLongitud)
  return grafoCaminos(n,a)
end

# Algoritmo de Bellman Ford
#-----------------------------------
function bellmanFord(g::grafoCaminos,origen::Int64)
  # paso 1
  ∞=typemax(Int32)
  tr=zeros(Int64,g.vertices)
  l=Array{Int64}(g.vertices)
  fill!(l,∞)
  l[origen]=0
  # paso 2 (recurrencia de programación dinámica)
  for i = 1:g.vertices-1 #número de arcos
    for v in 1:g.vertices
      for w in 1:g.vertices #dos loops para pasar por todos los arcos
        if l[w]> (l[v]+g.longitud[v,w])
          l[w]=l[v]+g.longitud[v,w]
          tr[w]=v
        end
      end
    end
  end
  # paso 3 (búsqueda de  un circuito)
  for v in 1:g.vertices
    for w in 1:g.vertices #dos loops para pasar por todos los arcos
      if l[w] > (l[v]+g.longitud[v,w])
        #println("longitud: ",l[w]," vs ",l[v]+g.longitud[v,w]," y v: ",v," w: ",w)
        visited=zeros(Bool,g.vertices)
        while visited[w]==false
          visited[w]=true
          w=tr[w]
        end
        return w,l,tr
      end
    end
  end
  return 0,l,tr
end

# Algoritmo de Dijkstra
#----------------------------------
function dijkstra(grafo::grafoCaminos,origen::Int64)
    ∞=typemax(Int32)
    tr=zeros(Int64,grafo.vertices)
    l=Array{Int64}(grafo.vertices)
    fill!(l,∞)
    l[origen]=0
    Q=PriorityQueue()
    enqueue!(Q,origen,0)
    while isempty(Q)==false
        v=dequeue!(Q)
        for w in 1:grafo.vertices
            if l[w] > (l[v]+grafo.longitud[v,w])
                l[w]=l[v]+grafo.longitud[v,w]
                tr[w]=v
                if haskey(Q,w)
                    Q[w]=l[w]
                else
                    enqueue!(Q,w,l[w])
                end
            end
            assert(l[w]>(0-10000000)) #warning
        end
    end
    return l,tr
end

#unGrafo=generarGrafoCaminos(25,10000)
#unGrafo.longitud[13,14]=1; unGrafo.longitud[14,15]=1; unGrafo.longitud[15,16]=1; unGrafo.longitud[17,16]=1000; unGrafo.longitud[17,13]=1; unGrafo.longitud[16,17]=(-10)
#conCircuito,longitud,traza=bellmanFord(unGrafo,1)
#println("traza: ",traza)
## Si he encontrado un circuito, imprimirlo
#if conCircuito>0
#  println("arco: (",conCircuito,",",traza[conCircuito],")")
#  w=traza[conCircuito]
#  while w != conCircuito
#    println("arco: (",w,",",traza[w],")")
#    w=traza[w]
#  end
#end
#longitud,traza=dijkstra(unGrafo,1) #si se descomenta salta la "assertion" de circuito negativo

######################################################
#
# Uso de caminos en el algoritmo de Ford-Fulkerson
#
######################################################

type grafoFlujos
    vertices::Int64
    capacidad::Array{Int64,2} #capacidad[i,j] indica la capacidad del arco
    solucion::Array{Int64,2}  #solucion[i,j] indica el flujo del arco
end

function generarGrafoFlow(n::Int64,maxCapacidad::Int64,density::Float64)
  a=Array{Int64}(n,n)
  b=Array{Int64}(n,n)
  rand!(a,1:maxCapacidad)
  for i in 1:n
    a[i,i]=0
    for j in i+1:n
      if rand()>(2*density) #números entre 0 y 1
        a[i,j]=0
        a[j,i]=0
      else # aceptaremos flujo en un único sentido 
        if rand()<0.5
          a[i,j]=0
        else
          a[j,i]=0
        end
      end
    end
  end
  return grafoFlujos(n,a,b)
end


# Implementación de Ford Fulkerson
#---------------------------------
function fordFulkerson(g::grafoFlujos,origen::Int64,destino::Int64)
  fill!(g.solucion,0) #limpiar la solución
  residual=grafoCaminos(g.vertices,zeros(Int64,g.vertices,g.vertices))
  obj=0
  println("g.capacidad. ",g.capacidad)
  while true 
    #creo el grafo residual
    fill!(residual.longitud,g.vertices+1)
    for i in 1:g.vertices
      for j in 1:g.vertices
        if g.capacidad[i,j]>0
          if g.solucion[i,j]<g.capacidad[i,j]
            residual.longitud[i,j]=1
          end
          if g.solucion[i,j]>0
            residual.longitud[j,i]=1
          end
        end
      end
    end
    #resuelvo Dijkstra
    #println(residual)
    longitud,traza=dijkstra(residual,origen)
    println("longitud:",longitud[destino])
    if longitud[destino]<g.vertices
      extraFlow=typemax(Int64)
      # primero tenemos que ver el flujo máximo que podemos pasar
      c=destino
      while true
        print("arco entre: ",traza[c]," y ",c)
        if g.capacidad[traza[c],c]>0
          #estoy añadiendo flujo
          extraFlow=min(extraFlow,g.capacidad[traza[c],c]-g.solucion[traza[c],c])
          println(" capacidad ",g.capacidad[traza[c],c]-g.solucion[traza[c],c]," extra: ",extraFlow)
        else
          #esto eliminando flujo (redirección)
          extraFlow=min(extraFlow,g.solucion[c,traza[c]])
          println(" rr ",g.solucion[c,traza[c]]," extra: ",extraFlow)
        end
        c=traza[c]
        if c==origen
          break
        end
      end
      # segundo tenemos que actualizar el flujo de los arcos según flujo máximo
      c=destino
      while true
        print("cambio en arco ",traza[c],",",c)
        if g.capacidad[traza[c],c]>0
          g.solucion[traza[c],c] += extraFlow
          println(" added ",extraFlow)
          assert(g.solucion[traza[c],c]<=g.capacidad[traza[c],c])
        else
          g.solucion[c,traza[c]] -= extraFlow
          println(" removed ",extraFlow)
          assert(g.solucion[traza[c],c]>=0)
        end
        c=traza[c]
        if c==origen
          break
        end
      end
      obj += extraFlow
    else
      #no podemos mejorar la solución
      return obj
    end
    #println("solucion: ",g.solucion)
    #println("================= fin un paso ================\n\n")
    #z=read(STDIN, Char)
  end
  return totalFlow
end

#gFlujos=generarGrafoFlow(10,500,0.45)
#maxFlow=fordFulkerson(gFlujos,1,10)
#println("maxFlow: ",maxFlow)

#gEjemplo=grafoFlujos(7,[0 1 3 0 0 0 0 ; 0 0 0 5 4 0 0 ; 0 0 0 3 0 0 0 ; 0 0 0 0 0 0 2 ; 0 0 0 0 0 2 0 ; 0 0 0 0 0 0 3 ; 0 0 0 0 0 0 0],zeros(Int64,7,7))
#maxFlow=fordFulkerson(gEjemplo,1,7)
#println("maxFlow: ",maxFlow)

######################################################
#
# Uso de caminos y flujos máximos para cálculo de flujo máximo a coste mínimo
#
######################################################


type grafoMinCost
    grafoF::grafoFlujos
    coste::Array{Int64,2}  #coste[i,j] indica el coste de pasar una unidad de flujo por el arco
end

function generarGrafoMinCost(n::Int64,maxCapacidad::Int64,maxCost::Int64,density::Float64)
  a=Array{Int64}(n,n)
  b=Array{Int64}(n,n)
  c=Array{Int64}(n,n)
  rand!(a,1:maxCapacidad)
  for i in 1:n
    a[i,i]=0
    for j in i+1:n
      if rand()>(2*density) #números entre 0 y 1
        a[i,j]=0
        a[j,i]=0
      else
        if rand()<0.5
          a[i,j]=0
        else
          a[j,i]=0
        end
      end
    end
  end
  for i in 1:n
    for j in 1:n
      if a[i,j]>0
        c[i,j]=rand(1:maxCost)
      else
        c[i,j]=0
      end
    end
  end
  return grafoMinCost(grafoFlujos(n,a,b),c)
end

# Implementación
#----------------------------------
function minCostMaxFlow(g::grafoMinCost,origen::Int64,destino::Int64)
  # primer paso. resolver maxflow
  maxFlow=fordFulkerson(g.grafoF,origen,destino)
  coste=0 # determinamos su coste
  for i in 1:g.grafoF.vertices
    for j in 1:g.grafoF.vertices
      if g.grafoF.solucion[i,j]>0
        coste += g.grafoF.solucion[i,j]*g.coste[i,j]
      end
    end
  end
  println("maxFlow: ",maxFlow,"\t","coste inicial: ",coste)
  # la idea ahora es la misma que e flujos máximos, pero usamos Bellman Ford para detectar un ciclo de coste negativo en el grafo
  residual=grafoCaminos(g.grafoF.vertices+1,zeros(Int64,g.grafoF.vertices+1,g.grafoF.vertices+1))
  while true
    #creo un grafo residual
    fill!(residual.longitud,typemax(Int32)) # mala praxis con el infinito
    for i in 1:g.grafoF.vertices
      for j in 1:g.grafoF.vertices
        if g.grafoF.capacidad[i,j]>0  #something wrong
          if g.grafoF.solucion[i,j]<g.grafoF.capacidad[i,j]
            residual.longitud[i,j]=g.coste[i,j]
          end
          if g.grafoF.solucion[i,j]>0
            residual.longitud[j,i]=0-g.coste[i,j]
          end
        end
      end
    end
    println("residual: ",residual)
    #resuelvo Bellman-Ford
    conCircuito,longitud,traza=bellmanFord(residual,origen)
    println("conCircuito: ",conCircuito," ",traza)
    if conCircuito!=0
      # encontrar el circuito
      cMin=typemax(Int32)
      w=traza[conCircuito]
      while w != conCircuito
        if residual.longitud[traza[w],w]>0 #arco que añade
          c=g.grafoF.capacidad[traza[w],w]-g.grafoF.solucion[traza[w],w]
        else # arco que reduce
          c=g.grafoF.solucion[w,traza[w]] 
        end
        cMin=min(c,cMin)
        println(w," ",traza[w]," -> ",residual.longitud[traza[w],w],"  ** ",c)
        w=traza[w]
      end
      if residual.longitud[traza[w],w]>0 # arco que añade
        c=g.grafoF.capacidad[traza[w],w]-g.grafoF.solucion[traza[w],w]
      else # arco que reduce
        c=g.grafoF.solucion[w,traza[w]]
      end
      cMin=min(c,cMin)
      println(w," ",traza[w]," -> ",residual.longitud[traza[w],w]," -- ",c)
      # alterar el circuito
      w=traza[conCircuito]
      while w != conCircuito
        if residual.longitud[traza[w],w]>0
          g.grafoF.solucion[traza[w],w] += cMin
          assert(g.grafoF.solucion[traza[w],w]<=g.grafoF.capacidad[traza[w],w])
          coste += cMin*g.coste[traza[w],w]
        else
          g.grafoF.solucion[w,traza[w]] -= cMin
          assert(g.grafoF.solucion[w,traza[w]]<=g.grafoF.capacidad[w,traza[w]])
          coste -= cMin*g.coste[w,traza[w]]
        end
        w=traza[w]
      end
      if residual.longitud[traza[w],w]>0
        g.grafoF.solucion[traza[w],w] += cMin
        assert(g.grafoF.solucion[traza[w],w]<=g.grafoF.capacidad[traza[w],w])
        coste += cMin*g.coste[traza[w],w]
      else # arco que reduce
        g.grafoF.solucion[w,traza[w]] -= cMin
        assert(g.grafoF.solucion[w,traza[w]]>=0)
        coste -= cMin*g.coste[w,traza[w]]
      end
      println("coste: ",coste)
    else
      return coste
    end
  end

end

gMinCost=generarGrafoMinCost(10,10,100,0.45)
coste=minCostMaxFlow(gMinCost,1,10)

#gMinCostEjemplo=grafoMinCost(grafoFlujos(4,[0 3 2 0; 0 0 1 0; 0 0 0 2; 0 0 0 0],zeros(Int64,4,4)),[0 10 50 0; 0 0 30 0; 0 0 0 20; 0 0 0 0])
#coste=minCostMaxFlow(gMinCostEjemplo,1,4)
#println("coste final: ",coste)
