#
#
# CPPAlgorithm based minimizations
#
#
export TV_Regularization_CPPA

"""
    TV_Regularization_CPPA(f,α, λ) - compute the TV regularization model of
 given data array f and paramater α and internal operator start λ.

 # Arguments
 * `f` an d-dimensional array of `ManifoldPoint`s
 * `α` parameter of the model (may be given as a vector to provide different
      weights to different directions)
 * `λ` internal parameter of the cyclic proxξmal point algorithm
 # Output
 * `x` the regulraized array
 # Optional Parameters
 * `MinimalChange` (`10.0^(-5)`) minimal change for the algorithm to stop
 * `MaxIterations` (`500`) maximal number of iterations
 * `FixedMask` : (`[]`) a binary mask of `size(f)` to fix certain input data, e.g. when
 impainting you might set the known ones to be FixedMask. The standard, an empty
 array sets none to be FixedMask.
 * `UnknownMask` : a binary mask indicating UnknownMask pixels that are inpainted

 This implementation is based on the article
> A. Weinmann, L. Demaret, M. Storath:
> Total Variation Regularization for Manifold-valued Data,
> SIAM J. Imaging Science, Vol. 7,
>

 ~ ManifoldValuedImageProcessing.jl ~ R. Bergmann ~ 2016-11-25
"""
function TV_Regularization_CPPA{T <: ManifoldPoint, S <: Number, R1 <: Bool, R2 <: Bool}(
      f::Array{T}, α::Array{S,1}, λ::Number;
      MinimalChange=10.0^(-9.0), MaxIterations=1000,
      FixedMask::Array{R1} = Array(Bool,0), UnknownMask::Array{R2} = Array(Bool,0)
      )::Array{T}
  if ( length(FixedMask) == 0 )
    FixedMask = falses(f)
  end
  if ( length(UnknownMask) == 0)
    UnknownMask = falses(f)
  end
  if length(α) == 1
    αV = α*ones(length(size(f)))
  else
    if length(α) ≠ length(size(f))
      sig1 = length(α);
      throw( ErrorException(string(" Length of α vector (",length(α),
        ") as to be the same as the number of dimensions of f (",length(size(f)),").")) )
    end
    αV=α;
  end
  stillUnknownMask = copy(UnknownMask);
  x = deepcopy(f)
  xold = deepcopy(x)
  iter = 1
  while (  ( (sum( [ distance(ξ,xoldi) for (ξ,xoldi) in zip(x[stillUnknownMask],xold[stillUnknownMask]) ] ) > MinimalChange)
    && (iter < MaxIterations) ) || (iter==1)  )
    xold = deepcopy(x)
    # First term: d(f,x)^2
    for i in eachindex(x)
      x[i] = proxDistanceSquared(f[i],λ/i,x[i])
    end
    # TV term
    for d in 1:ndims(f)
      e_d  = zeros(ndims(f))
      e_d[d] = 1;
      for i in eachindex(f)
        # neighbor index
        i2 = sub2ind(size(f), [sum(x) for x in zip( ind2sub(size(f), i), e_d)] )
        print(i)
        print(i2)
        if ( i2 <=length(f) )
          if stillUnknownMask[i]
            x[i] = x[i2]; stillUnknownMask[i] = false;
          elseif stillUnknownMask[i2]
            x[i2] = x[i]; stillUnknownMask[i] = false;
          else # both known
            (a,b) = proxTV((x[i], x[i2]),αV[d]*λ/i)
            if !FixedMask[i]
              x[i] = a;
            end
            if !FixedMask[i2]
              x[i2] = b;
            end
          end #endif known
        end #endif inrange
      end #end for i
    end #end for d
    iter +=1
  end #end while
  return x,iter, sum( [ distance(ξ,xoldi) for (ξ,xoldi) in zip(x[stillUnknownMask],xold[stillUnknownMask]) ] )
end
