using DataStructures # -> definir una cola de prioridad


#######################################################
#
# Funcionamiento del algoritmo de Bellman Ford
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

# Muestra cómo funciona Bellman-Ford
#-----------------------------------
function bellmanFord(g::grafoCaminos,origen::Int64)
  # paso 1
  ∞=1000000
  tr=zeros(Int64,g.vertices)
  l=Array{Int64}(g.vertices)
  fill!(l,∞)
  l[origen]=0
  # paso 2 (recurrencia de programación dinámica)
  for i = 1:g.vertices-1 #número de pasos
    for v in 1:g.vertices
      for w in 1:g.vertices #dos loops para pasar por todos los arcos
        if l[w]> (l[v]+g.longitud[v,w])
          l[w]=l[v]+g.longitud[v,w]
          tr[w]=v
        end
      end
    end
  end
  # paso 3 (búsqueda de una incompatibilidad que muestra la existencia de un circuito)
  for v in 1:g.vertices
    for w in 1:g.vertices #dos loops para pasar por todos los arcos
      if l[w] > (l[v]+g.longitud[v,w])
        println("longitud: ",l[w]," vs ",l[v]+g.longitud[v,w]," y v: ",v," w: ",w)
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

unGrafo=generarGrafoCaminos(25,10000)
unGrafo.longitud[13,14]=1; unGrafo.longitud[14,15]=1; unGrafo.longitud[15,16]=1; unGrafo.longitud[17,16]=1000; unGrafo.longitud[17,13]=1; unGrafo.longitud[16,17]=(-10)
conCircuito,longitud,traza=bellmanFord(unGrafo,1)
println("traza: ",traza)
# Si he encontrado un circuito, imprimirlo
if conCircuito>0
  println("conCircuito: ",conCircuito," ",traza[conCircuito])
  w=traza[conCircuito]
  while w != conCircuito
    println(w," ",traza[w])
    w=traza[w]
  end
end

#######################################################
#
# Uso de Bellman-Ford en el algoritmo de Ford-Fulkerson
#
######################################################

type grafoFlujos
    vertices::Int64
    capacidad::Array{Int64,2} #arco[i,j] indica la capacidad del arco
end

function generarGrafoFlow(n::Int64,maxCapacidad::Int64,density::Float64)
  a=Array{Int64}(n,n)
  rand!(a,1:maxCapacidad)
  for i in 1:n
    for j in i+1:n
      if rand()<(2*density) #números entre 0 y 1
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
  return grafoFlujos(n,a)
end


# Implementación de Ford Fulkerson
#---------------------------------
function fordFulkerson(g::grafoFlujos,origen::Int64,destino::Int64,s::Array{Int64,2})
  s=zeros(Int64,g.vertices,g.vertices)
  residual=grafoCaminos(g.vertices,zeros(Int64,g.vertices,g.vertices))
  while true
    residual.longitud=zeros(Int64,g.vertices,g.vertices)
    for i in 1:g.vertices
      for j in 1:g.vertices
        if g.capacidad[i,j]>0
    break
  end
end

unGrafo=generarGrafoFlow(25,100,0.25)

solucion=Array{Int64}(unGrafo.vertices,unGrafo.vertices)
fordFulkerson(unGrafo,1,25,solucion)
#
##longitud,traza=djDense(unGrafo,1)
##println(unGrafo.arcos)
##println(longitud)
##println(traza)
#
#
########################################################
##
## Grafo sparse
##
#######################################################
#
#type arco
#    origen::Int64
#    destino::Int64
#    longitud::Int64
#end
#
#type grafoSparse
#    nVertices::Int64
#    nArcos::Int64
#    pOrigen::Array{Int64,1}
#    arcos::Array{arco,1} #arco[i,j] indica la distancia entre i y j
#end
#
#function djSparse(origen::Int64,g::grafoSparse)
#    ∞=1000000
#    π=zeros(Int64,g.nVertices)
#    l=Array{Int64}(g.nVertices)
#    fill!(l,∞)
#    l[origen]=0
#    Q=PriorityQueue()
#    enqueue!(Q,origen,0)
#    while isempty(Q)==false
#        v=dequeue!(Q)
#        for c in g.pOrigen[v]:g.pOrigen[v+1]-1
#            w=g.arcos[c].destino
#            longitud=g.arcos[c].longitud
#            if l[w] > (l[v]+longitud)
#                l[w]=l[v]+longitud
#                π[w]=v
#                if haskey(Q,w)
#                    Q[w]=l[w]
#                else
#                    enqueue!(Q,w,l[w])
#                end
#            end
#        end
#    end
#    return l,π
#end
#
#function generarGrafoSparse(n::Int64,p::Float64,maxValue::Int64)
#    a=arco[]
#    pOrigen=Int64[]
#    nArcos=1
#    for i in 1:n
#        push!(pOrigen,nArcos)
#        for j in 1:n
#            if i!=j
#                if rand()<p
#                    push!(a,arco(i,j,rand(1:maxValue)))
#                    nArcos += 1
#                end
#            end
#        end
#    end
#    push!(pOrigen,nArcos)
#    return grafoSparse(n,nArcos-1,pOrigen,a)
#end
#
#unGrafo=generarGrafoSparse(10,0.25,1000)
#println(unGrafo.pOrigen)
#println(unGrafo.arcos)
#longitud,camino=djSparse(1,unGrafo)
#println(longitud)
#println(camino)
#
########################################################
##
## Programación Dinámica
##
#######################################################
#
#beneficio = [ 5, 3, 2, 7, 4 ]
#peso = [ 2, 8, 4, 2, 5 ]
#capacidad = 10
#
#function knapsack(b,p,c)
#    T=size(p,1) #número de etapas
#    tabla = OffsetArray(Int64, 0:c, 1:T) #las filas representan la capacidad ocupada, las columnas las decisiones
#    #etapa 1
#    for s=1:c
#        tabla[s,1]=(-1) #valor negativo va a indicar que no es valor posible
#    end
#    tabla[0,1]=0
#    tabla[p[1],1]=b[1]
#    #etapas 2 a T
#    #println(tabla[:,1]) #--> permitirá explicar el funcionamiento del algoritmo
#    for t in 2:T
#        for s=0:c
#            tabla[s,t]=tabla[s,t-1]
#        end
#        for s=c-p[t]:-1:0 #este for va de c-p[t] hasta 0 reduciendo en 1 cada vez
#            if tabla[s,t]>=0 #contiene un valor posible
#                if tabla[s+p[t],t]<(tabla[s,t-1]+b[t]) #mejora la opción actual?
#                    tabla[s+p[t],t]=tabla[s,t-1]+b[t]
#                end
#            end
#        end
#        #println(tabla[:,t]) #--> permitirá explicar el funcionamiento del algoritmo
#    end
#    beneficio=0
#    maxLoad=0
#    previous=0
#    for s in 0:c
#        if beneficio < tabla[s,T]
#            beneficio=tabla[s,T]
#        end
#    end
#    return beneficio
#end
#
#beneficio=knapsack(beneficio,peso,capacidad)
#println(beneficio)
