using OffsetArrays # -> Nos permitirá usar matrices que empiecen con índice 0, es lento pero cómodo en este caso
using DataStructures # -> definir una cola de prioridad


#######################################################
#
# Grafo denso
#
######################################################

type grafoDenso
    vertices::Int64
    arcos::Array{Int64,2} #arco[i,j] indica la distancia entre i y j
end

function djDense(grafo::grafoDenso,origen::Int64)
    ∞=1000000
    π=zeros(Int64,grafo.vertices)
    l=Array{Int64}(grafo.vertices)
    fill!(l,∞)
    l[origen]=0
    Q=PriorityQueue()
    enqueue!(Q,origen,0)
    while isempty(Q)==false
        v=dequeue!(Q)
        for w in 1:grafo.vertices
            if l[w] > (l[v]+grafo.arcos[v,w])
                l[w]=l[v]+grafo.arcos[v,w]
                π[w]=v
                if haskey(Q,w)
                    Q[w]=l[w]
                else
                    enqueue!(Q,w,l[w])
                end
            end
        end
    end
    return l,π
end

function generarGrafoDense(n::Int64,maxValue::Int64)
    a=Array{Int64}(n,n)
    rand!(a,1:maxValue)
    for i in 1:n
        a[i,i]=0
    end
    return grafoDenso(n,a)
end

unGrafo=generarGrafoDense(25,1000)
longitud,traza=djDense(unGrafo,1)
#println(unGrafo.arcos)
#println(longitud)
#println(traza)


#######################################################
#
# Grafo sparse
#
######################################################

type arco
    origen::Int64
    destino::Int64
    longitud::Int64
end

type grafoSparse
    nVertices::Int64
    nArcos::Int64
    pOrigen::Array{Int64,1}
    arcos::Array{arco,1} #arco[i,j] indica la distancia entre i y j
end

function djSparse(origen::Int64,g::grafoSparse)
    ∞=1000000
    π=zeros(Int64,g.nVertices)
    l=Array{Int64}(g.nVertices)
    fill!(l,∞)
    l[origen]=0
    Q=PriorityQueue()
    enqueue!(Q,origen,0)
    while isempty(Q)==false
        v=dequeue!(Q)
        for c in g.pOrigen[v]:g.pOrigen[v+1]-1
            w=g.arcos[c].destino
            longitud=g.arcos[c].longitud
            if l[w] > (l[v]+longitud)
                l[w]=l[v]+longitud
                π[w]=v
                if haskey(Q,w)
                    Q[w]=l[w]
                else
                    enqueue!(Q,w,l[w])
                end
            end
        end
    end
    return l,π
end

function generarGrafoSparse(n::Int64,p::Float64,maxValue::Int64)
    a=arco[]
    pOrigen=Int64[]
    nArcos=1
    for i in 1:n
        push!(pOrigen,nArcos)
        for j in 1:n
            if i!=j
                if rand()<p
                    push!(a,arco(i,j,rand(1:maxValue)))
                    nArcos += 1
                end
            end
        end
    end
    push!(pOrigen,nArcos)
    return grafoSparse(n,nArcos-1,pOrigen,a)
end

unGrafo=generarGrafoSparse(10,0.25,1000)
println(unGrafo.pOrigen)
println(unGrafo.arcos)
longitud,camino=djSparse(1,unGrafo)
println(longitud)
println(camino)

#######################################################
#
# Programación Dinámica
#
######################################################

beneficio = [ 5, 3, 2, 7, 4 ]
peso = [ 2, 8, 4, 2, 5 ]
capacidad = 10

function knapsack(b,p,c)
    T=size(p,1) #número de etapas
    tabla = OffsetArray(Int64, 0:c, 1:T) #las filas representan la capacidad ocupada, las columnas las decisiones
    #etapa 1
    for s=1:c
        tabla[s,1]=(-1) #valor negativo va a indicar que no es valor posible
    end
    tabla[0,1]=0
    tabla[p[1],1]=b[1]
    #etapas 2 a T
    #println(tabla[:,1]) #--> permitirá explicar el funcionamiento del algoritmo
    for t in 2:T
        for s=0:c
            tabla[s,t]=tabla[s,t-1]
        end
        for s=c-p[t]:-1:0 #este for va de c-p[t] hasta 0 reduciendo en 1 cada vez
            if tabla[s,t]>=0 #contiene un valor posible
                if tabla[s+p[t],t]<(tabla[s,t-1]+b[t]) #mejora la opción actual?
                    tabla[s+p[t],t]=tabla[s,t-1]+b[t]
                end
            end
        end
        #println(tabla[:,t]) #--> permitirá explicar el funcionamiento del algoritmo
    end
    beneficio=0
    maxLoad=0
    previous=0
    for s in 0:c
        if beneficio < tabla[s,T]
            beneficio=tabla[s,T]
        end
    end
    return beneficio
end

beneficio=knapsack(beneficio,peso,capacidad)
println(beneficio)
