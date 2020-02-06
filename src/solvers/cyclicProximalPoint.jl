export cyclicProximalPoint
@doc raw"""
    cyclicProximalPoint(M, F, proximalMaps, x)

perform a cyclic proximal point algorithm.

# Input
* `M` – a manifold $\mathcal M$
* `F` – a cost function $F\colon\mathcal M\to\mathbb R$ to minimize
* `proximalMaps` – an Array of proximal maps (`Function`s) `(λ,x) -> y` for the summands of $F$
* `x` – an initial value $x ∈ \mathcal M$

# Optional
the default values are given in brackets
* `evaluationOrder` – ( [`LinearEvalOrder`](@ref) ) – whether
  to use a randomly permuted sequence ([`FixedRandomEvalOrder`](@ref)), a per
  cycle permuted sequence ([`RandomEvalOrder`](@ref)) or the default linear one.
* `λ` – ( `iter -> 1/iter` ) a function returning the (square summable but not
  summable) sequence of λi
* `stoppingCriterion` – ([`stopWhenAny`](@ref)`(`[`stopAfterIteration`](@ref)`(5000),`[`stopWhenChangeLess`](@ref)`(10.0^-8))`) a [`StoppingCriterion`](@ref).
* `returnOptions` – (`false`) – if actiavated, the extended result, i.e. the
  complete [`Options`](@ref) are returned. This can be used to access recorded values.
  If set to false (default) just the optimal value `xOpt` if returned
and the ones that are passed to [`decorateOptions`](@ref) for decorators.

# Output
* `xOpt` – the resulting (approximately critical) point of gradientDescent
OR
* `options` - the options returned by the solver (see `returnOptions`)
"""
function cyclicProximalPoint(M::MT,
  F::Function, proximalMaps::Array{Function,N} where N, x0;
  evaluationOrder::EvalOrder = LinearEvalOrder(),
  stoppingCriterion::StoppingCriterion = stopWhenAny( stopAfterIteration(5000), stopWhenChangeLess(10.0^-12)),
  λ = i -> typicalDistance(M)/2/i,
  returnOptions=false,
  kwargs... #decorator options
  ) where {MT <: Manifold}
    p = ProximalProblem(M,F,proximalMaps)
    o = CyclicProximalPointOptions(x0,stoppingCriterion,λ,evaluationOrder)

    o = decorateOptions(o; kwargs...)
    resultO = solve(p,o)
    if returnOptions
        return resultO
    else
        return getSolverResult(resultO)
    end
end
function initializeSolver!(p::ProximalProblem, o::CyclicProximalPointOptions)
    c = length(p.proximalMaps)
    o.order = updateOrder(c,0,[1:c...],o.orderType)
end
function doSolverStep!(p::ProximalProblem, o::CyclicProximalPointOptions, iter)
    c = length(p.proximalMaps)
    λi = o.λ(iter)
    for k=o.order
        o.x = getProximalMap(p,λi,o.x,k)
    end
    o.order = updateOrder(c,iter,o.order,o.orderType)
end
getSolverResult(o::CyclicProximalPointOptions) = o.x
updateOrder(n,i,o,::LinearEvalOrder) = o
updateOrder(n,i,o,::RandomEvalOrder) = collect(1:n)[randperm(length(o))]
updateOrder(n,i,o,::FixedRandomEvalOrder) = (i==0) ? collect(1:n)[randperm(length(o))] : o
