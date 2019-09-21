# inicializar datos
using JuMP
using GLPKMathProgInterface

#######################################################################
#
# modelo simple (2 variables y 1 restricción)
#
#######################################################################

m = Model(solver = GLPKSolverLP())
@variable(m, 0 <= x <= 10 )
@variable(m, 0 <= y <= 30 )

@objective(m, Max, 5x + 3*y )
@constraint(m, 2x + 3y <= 35.0 )

print(m)

status = solve(m)

println("Status: ",status," Objective value: ", getobjectivevalue(m))
println("x = ", getvalue(x))
println("y = ", getvalue(y))

#######################################################################
#
# modelo 2 (Standard form LP)
#
#######################################################################


# DECLARACION DEL DATOS
#------------------------

c=[-2500; -4000; 0; 0; 0] 
b=[200; 100; 750]
A=[1 0 1 0 0; 0 1 0 1 0; 3 5 0 0 1]
m, n = size(A) # m = filas n = columnas

# DECLARACION DEL MODELO
#------------------------

modelo = Model(solver = GLPKSolverLP())
@variable(modelo, x[1:n] >= 0) # Modela x >=0
for i in 1:m # vamos a construir restricciones una a una
    @constraint(modelo, sum(A[i, j]*x[j] for j in 1:n) == b[i]) # i-ésima restricción 
end 
@objective(modelo,Min,sum(c[i]*x[i] for i in 1:n))
status = solve(modelo) # resolvemos el modelo  
println(getobjectivevalue(modelo))
println(getvalue(x))

#######################################################################
#
# modelo 3 (Set covering problem)
#
#######################################################################

# Leer datos (with care)
#------------------------

run(`wget -O scp41.txt http://people.brunel.ac.uk/~mastjjb/jeb/orlib/files/scp41.txt`)
run(`cat scp41.txt`)

function readFile(filename)
    f=open(filename,"r")
    s=readstring(f)
    close(f)
    s=replace(s,"\n","")
    s=split(s," ")
    nC=parse(Int64,s[2]) #numero de restricciones
    nV=parse(Int64,s[3]) #numero of variables
    numCoefFo=0 #contadores para procesar la información
    numCoef=0
    numRow=0
    c= Float64[] #vector donde guardar los coeficientes de la función objetivo
    #método para almacenar una matriz (o un grafo) sparse
    I=Int64[] #puntero a fila
    J=Int64[] # puntero a columna
    V=Float64[] # puntero a valor
    for i in 4:length(s)
        if s[i]!= ""
            if numCoefFo < nV
                push!(c,parse(Float64,s[i]))
                numCoefFo += 1
            else
                if numCoef == 0
                    numRow += 1
                    numCoef = parse(Int64,s[i])
                else
                    numCoef -= 1
                    push!(I,numRow)
                    push!(J,parse(Int64,s[i]))
                    push!(V,1.0)
                end
            end
        end
    end
    A=sparse(I,J,V) #crea una matriz optimizada para no guardar ceros
    return nC,nV,c,A #,c,A
end

constraints,variables,c,A = readFile("scp41.txt")

println("\n\n",constraints," ",variables)
println("\n\n",c)
println("\n\n",A)

# Resolver el problema con GLPK
#------------------------------

scp=Model(solver = GLPKSolverMIP())
@variable(scp, x[1:variables],Bin)

# si se quiere la versión relajada
#scp=Model(solver=GLPKSolverLP())
#@variable(scp, x[1:variables] >= 0)

#función objetivo a minimizar
@objective(scp, Min, sum(c[j]*x[j] for j in 1:variables))

for i in 1:constraints
    @constraint(scp,sum(A[i,j]*x[j] for j in 1:variables) >=1 )
end

#escribimos el modelo
#print(scp)

#resolvemos
status = solve(scp)

#mostramos resultados
println("**** Status: ",status," Objective value: ", getobjectivevalue(scp))
println("**** x = ", getvalue(x))


# Construcción alternativa del modelo
#------------------------------------

scpAlt=Model(solver = GLPKSolverMIP())
@variable(scpAlt, xAlt[1:variables],Bin)

#función objetivo a minimizar
Expr = AffExpr()
for j in 1:variables
    push!(Expr, c[j], xAlt[j])
end
@objective(scpAlt, Min, Expr)

for i in 1:constraints
    Expr = AffExpr()
    for j in 1:variables
        push!(Expr,A[i,j],xAlt[j])
    end
    @constraint(scpAlt,Expr >= 1)
end

#escribimos el modelo
#print(scpAlt)

#resolvemos
status = solve(scpAlt)

#mostramos resultados
println("**** Status: ",status," Objective value: ", getobjectivevalue(scpAlt))
for i in 1:variables
    if getvalue(xAlt[i])>0.99
        println(i,"\t",xAlt[i])
    end
end

#######################################################################
#
# heurística constructiva
#
#######################################################################

# inicializar datos
#------------------

solucion=zeros(Bool,variables)
cubre=zeros(Int64,variables)		# cubre[i] indica el número de restricciones que "cubre" la variable i
cubierta=zeros(Bool,constraints)
sinCubrir=constraints
costeSolucion=0

# determinamos el número de restricciones que cubre inicialmente cada variable
#-----------------------------------------------------------------------------

for i in 1:variables
    for j in 1:constraints
        if A[j,i]==1
            cubre[i] += 1
        end
    end
end

# algoritmo en sí
#-----------------

while sinCubrir>0
    bestI::Int64=0
    bestCoste=typemax(Float64) #puede igualarse bestCoste a un valor muy alto
    for i in 1:variables
        if solucion[i]==false #si no, no vale la pena y evitamos un problema desde un punto computacional
            costePorRestriccion=c[i]/cubre[i]
            if costePorRestriccion<bestCoste #es el mejor hasta el momento?
                bestCoste=costePorRestriccion
                bestI=i
            end
        end
    end
    #Aqui tenemos al mejor que es bestI
    @assert bestI!=0 #si pasa esto ha habido un error
    solucion[bestI]=true #actualizamos solución
    costeSolucion+=c[bestI] #actualizamos coste acumulado de la solución en construcción
    for j in 1:constraints #vamos a ver qué restricciones han pasado a estar cubiertas
        if A[j,bestI]==1 && cubierta[j]==false
            cubierta[j]=true #si pasan a estar cubiertas
            sinCubrir -= 1
            for i in 1:variables #vamos a ver qué variables eran las que las cubrian
                if A[j,i]==1
                    cubre[i] -= 1
                end
            end
        end
    end
    @assert cubre[bestI]==0
    println("he escogido ",bestI," quedan por cubrir ",sinCubrir," coste acumulado: ",costeSolucion)
end

