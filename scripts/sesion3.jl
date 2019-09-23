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

function dj(g::grafoCaminos,origen::Int64)
    ∞=1000000
    tr=zeros(Int64,g.vertices)
    l=Array{Int64}(g.vertices)
    fill!(l,∞)
    l[origen]=0
    Q=PriorityQueue()
    enqueue!(Q,origen,0)
    while isempty(Q)==false
        v=dequeue!(Q)
        for w in 1:g.vertices
            if l[w] > (l[v]+g.longitud[v,w])
                l[w]=l[v]+g.longitud[v,w]
                if l[w]<0 #condición adicional para evitar loop infinito
                  return l,tr
                end
                tr[w]=v
                if haskey(Q,w)
                    Q[w]=l[w]
                else
                    enqueue!(Q,w,l[w])
                end
            end
        end
    end
    return l,tr
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
longitud,traza=dj(unGrafo,1)
println("traza (dj): ",traza)
println("longitud (dj): ",longitud)

#######################################################
#
# Uso de caminos para el cálculo de flujos
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
  return grafoFlujos(n,a)
end


# Implementación de Ford Fulkerson
#---------------------------------
function maxFlow(g::grafoFlujos,origen::Int64,destino::Int64,s::Array{Int64,2})
  s=zeros(Int64,g.vertices,g.vertices)
  totalFlow=0
  residual=grafoCaminos(g.vertices,zeros(Int64,g.vertices,g.vertices))
  println("capacidad inicial: ",g.capacidad)
  while true
    fill!(residual.longitud,g.vertices+2)
    for i in 1:g.vertices
      for j in 1:g.vertices
        if s[i,j]<g.capacidad[i,j]
          residual.longitud[i,j]=1
        end
        if s[i,j]>0
          residual.longitud[j,i]=1
        end
      end
    end
    println("residual: ",residual)
    longitud,traza=dj(residual,origen)
    println("Longitud: ",longitud)
    println("traza: ",traza)
    if longitud[destino]<(g.vertices+1)
      # tenemos camino aumentante
      current=destino
      flowExtra=10000000 # mala praxis
      while current != origen
        if g.capacidad[traza[current],current]>0
          remaining=g.capacidad[traza[current],current]-s[traza[current],current]
        else
          remaining=s[current,traza[current]]
        end
        if remaining<flowExtra
          flowExtra=remaining
        end
        current=traza[current]
      end
      # ahora sabemos que el flujo aumenta en flowExtra, así que vamos sumando/restando
      totalFlow += flowExtra
      current=destino
      while current != origen
        if g.capacidad[traza[current],current]>0
          s[traza[current],current] += flowExtra
          assert(s[traza[current],current] <= g.capacidad[traza[current],current])
        else
          s[current,traza[current]] -= flowExtra
          assert(s[current,traza[current]] >= 0)
        end
      end
    else
      # no podemos mejorar la solución actual
      break 
    end
  end
  return totalFlow,s
end

unGrafo=generarGrafoFlow(25,100,0.4)

solucion=Array{Int64}(unGrafo.vertices,unGrafo.vertices)
flujo,solucion=maxFlow(unGrafo,1,25,solucion)
println("flujo: ",flujo)
println("Solución: ",solucion)
#
##longitud,traza=djDense(unGrafo,1)
##println(unGrafo.arcos)
##println(longitud)
##println(traza)
#
#

