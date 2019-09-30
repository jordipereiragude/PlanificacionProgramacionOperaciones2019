# Estructuras de instancia y solución
#------------------------------------
type instance 
  nTareas::Int64
  duraciones::Array{Int64,1}
  precedencias::Array{Int8,2}
  absPrecedencias::Array{Int8,2}
  ciclo::Int64
end

type solucion
  asignacion::Array{Int64,1}
  estaciones::Int64
  ciclo::Int64
  cicloPorEstacion::Array{Int64,1}
end

function leerArchivo(filename)
  f=open(filename,"r")
  s=readlines(f)
  close(f)
  nTareas=parse(Int64,s[1])
  duraciones=Int64[]
  for i in 2:nTareas+1
    push!(duraciones,parse(Int64,s[i]))
  end
  i=nTareas+2
  precedencias=zeros(Int8,nTareas,nTareas)
  absPrecedencias=zeros(Int8,nTareas,nTareas)

  while true
    v=split(s[i],",")
    #println(v[1],"\t",v[2])
    origen=parse(Int64,v[1])
    destino=parse(Int64,v[2])
    if origen==(-1) 
      break 
    end
    precedencias[origen,destino]=1
    absPrecedencias[origen,destino]=1
    i+=1
  end
  cambio=true
  while cambio
    cambio=false
    for i in 1:nTareas
      for j in 1:nTareas
        if absPrecedencias[i,j]==1
          for k in 1:nTareas
            if absPrecedencias[i,k]==0 && absPrecedencias[j,k]==1
              absPrecedencias[i,k]=1
              cambio=true
            end
          end
        end
      end
    end
  end
  return(nTareas,duraciones,precedencias,absPrecedencias)
end

function constructiva(inst::instance)
  s=solucion(zeros(Int64,nTareas),0,0,zeros(Int64,nTareas))
  pending=zeros(Int64,nTareas)
  for i in 1:inst.nTareas
    pending[i]=sum(inst.precedencias[:,i])
  end
  tiempoLibre=inst.ciclo
  estacion=1
  numTareas=0
  while numTareas < inst.nTareas
    bestTarea=0
    bestDuracion=0
    for i in 1:inst.nTareas
      if pending[i]==0 && inst.duraciones[i]<=tiempoLibre && bestDuracion<inst.duraciones[i]
        bestTarea=i
        bestDuracion=inst.duraciones[i]
      end
    end
    #print("bestTareas: ",bestTarea)
    if bestTarea>0
      numTareas += 1
      tiempoLibre -= inst.duraciones[bestTarea]
      s.asignacion[bestTarea]=estacion
      pending[bestTarea]=(-1)
      for i in 1:inst.nTareas
        if inst.precedencias[bestTarea,i]==1
          pending[i] -= 1
        end
      end
    else #es igual a 0
      s.cicloPorEstacion[estacion]=inst.ciclo-tiempoLibre
      estacion += 1
      tiempoLibre=inst.ciclo
    end
    #println(" pendientes. ",pending)
  end
  s.cicloPorEstacion[estacion]=inst.ciclo-tiempoLibre
  s.estaciones=estacion
  s.ciclo=maximum(s.cicloPorEstacion)
  return s
end

function checkEarliest(tarea::Int64,inst::instance,s::solucion)
  retorno=1  
  for i in 1:inst.nTareas
    if inst.absPrecedencias[i,tarea]==1
      retorno=max(retorno,s.asignacion[i])
    end
  end
  return retorno
end

function checkLatest(tarea::Int64,inst::instance,s::solucion)
  retorno=s.estaciones
  for i in 1:inst.nTareas
    if inst.absPrecedencias[tarea,i]==1
      retorno=min(retorno,s.asignacion[i])
    end
  end
  return retorno
end

function mejoraLocal(inst::instance,s::solucion)
  earliest=zeros(Int64,nTareas)
  latest=zeros(Int64,nTareas)
  for i in 1:inst.nTareas
    earliest[i]=checkEarliest(i,inst,s)
    latest[i]=checkLatest(i,inst,s)
  end
  println("earliest: ",earliest)
  println("latest: ",latest)
  println("solución inicial: ",latest)
  #cambiar una tarea de estacion
  while true
    cambio=false
    for i in 1:inst.nTareas
      #en estacion crítica
      if s.cicloPorEstacion[s.asignacion[i]]==s.ciclo
        for j in earliest[i]:latest[i]
          if s.cicloPorEstacion[j]+inst.duraciones[i] < s.ciclo # reduce el tiempo de ciclo
            #mejora
            cambio=true
            s.cicloPorEstacion[s.asignacion[i]] -= inst.duraciones[i]
            s.cicloPorEstacion[j] += inst.duraciones[i]
            s.ciclo=maximum(s.cicloPorEstacion)
            s.asignacion[i]=j
            for k in 1:inst.nTareas #mejorable
              earliest[k]=checkEarliest(k,inst,s)
              latest[k]=checkLatest(k,inst,s)
            end
          end
        end
      end
    end
    if cambio==false
      break
    end
  end
  #intercambiar dos tareas
  while true
    cambio=false
    for i in 1:inst.nTareas
      if s.cicloPorEstacion[s.asignacion[i]]==s.ciclo #en estación crítica
        for j in 1:inst.nTareas
          if inst.absPrecedencias[i,j]==0 && i!=j
            #pueden ir en las estaciones que els toca
            if s.asignacion[i]>=earliest[j] && s.asignacion[i]<=latest[j] && s.asignacion[j]>=earliest[i] && s.asignacion[j]<=latest[i]
              if (s.cicloPorEstacion[s.asignacion[i]]-inst.duraciones[i]+inst.duraciones[j])<s.ciclo && 
                 (s.cicloPorEstacion[s.asignacion[j]]-inst.duraciones[j]+inst.duraciones[i])<s.ciclo 
                #println("\tcambio: ",i,"\t",j)
                cambio=true
                s.cicloPorEstacion[s.asignacion[i]] = s.cicloPorEstacion[s.asignacion[i]]-inst.duraciones[i]+inst.duraciones[j]
                s.cicloPorEstacion[s.asignacion[j]] = s.cicloPorEstacion[s.asignacion[j]]-inst.duraciones[j]+inst.duraciones[i]
                s.ciclo=maximum(s.cicloPorEstacion)
                s.asignacion[i],s.asignacion[j] = s.asignacion[j],s.asignacion[i]
                for k in 1:inst.nTareas
                  earliest[k]=checkEarliest(k,inst,s)
                  latest[k]=checkLatest(k,inst,s)
                end
              end
            end
          end
        end
      end
    end
    println("solucion: ",s)
    if cambio==false
      break
    end
  end
  return s
end

#leer datos
#nTareas,duraciones,precedencias,absPrecedencias=leerArchivo("Ejemplo0.in2")
#instancia=instance(nTareas,duraciones,precedencias,absPrecedencias,20)
#println("inst: ",instancia)

nTareas,duraciones,precedencias,absPrecedencias=leerArchivo("Ejemplo1.in2")
instancia=instance(nTareas,duraciones,precedencias,absPrecedencias,1000)
#println("inst: ",instancia)

#solución inicial
miSolucion=constructiva(instancia)
println("solucion: ",miSolucion)

#Mejora local
miSolucion=mejoraLocal(instancia,miSolucion)
println("solucion: ",miSolucion)
