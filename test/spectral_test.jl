using Test

@testset "spectral" begin
    RankedArray = MatrixNetworks.RankedArray

    @testset "RankedArray" begin
        n = 10
        v = rand(n)
        p = sortperm(v,rev=true)
        r = RankedArray(p)

        @test haskey(r,3) == true
        @test haskey(r,-1) == false
        @test haskey(r,0) == false
        @test haskey(r,n+1) == false

        @test_throws DimensionMismatch sweepcut(sparse(zeros(1,1)),v)
    end
    @testset "integers" begin
        n = 6
        x = collect(1.:Float64(n))
        A = sparse(1:n-1,2:n,1,n,n)
        A = A + A' + sparse(1.0I,n,n)
        profile = sweepcut(A,x)
        @test argmin(profile.conductance) == 3
        @test all(profile.cut .== 1)
    end
    @testset "floats" begin
        n = 6
        x = collect(1.:Float64(n))
        A = sparse(1:n-1,2:n,0.5,n,n)
        A = A + A' + sparse(1.5I,n,n)
        profile = sweepcut(A,x)
        @test argmin(profile.conductance) == 3
        @test all(profile.cut .== 0.5)
    end
    @testset "complement set" begin
        # Test an example where we need to take
        # the complement set
        n = 6
        A = sparse(1:n-1,2:n,1,n,n)
        A = A + A'
        x = [6,3,5,4,2,1]
        profile = sweepcut(A,x)
        @test length(bestset(profile)) == 2
    end
    @testset "spectral_cut" begin
        n = 50
        A = sparse(1:n-1,2:n,1,n,n)
        A = A + A'
        output = spectral_cut(A,true,true)

        (x,lam2) = fiedler_vector(sparse(zeros(1,1)))
        profile = sweepcut(sparse(zeros(1,1)),x)
        @test isempty(profile.conductance)

        @test_throws ArgumentError fiedler_vector(sparse(1.0I,2,2) + sparse([1],[2],1.,2,2))

        @test isempty(spectral_cut(sparse(zeros(5,5)),true,true).set)
        n = 50
        A = sparse(1:n-1,2:n,1.,n,n)
        A = A + A'
        @test length(spectral_cut(A).set) == 25

        n = 100
        A = sparse(ones(n,n))
        @test length(spectral_cut(A).set) == 50

        M = MatrixNetwork(A)
        @test length(spectral_cut(M).set) == 50

        @test_throws ArgumentError spectral_cut(sparse(1.0I,2,2) + spdiagm(1=>[1]), true, false)
        @test_throws ArgumentError spectral_cut(-sparse(1.0I,2,2), false, false) 
    end
    dtol = 1.e-8 # default tolerance
    @testset "fiedler_vector" begin
        v,lam2 = fiedler_vector(sparse(zeros(1,1)))
        @test all(v .== [0.])
        # Newman's netscience graph in case anyone care ...
        A = sparse([2,3,4,5,16,44,113,131,250,259,1,3,1,2,1,5,13,14,15,16,44,45,46,47,61,126,127,128,146,152,153,154,164,165,166,176,177,249,250,274,313,314,323,324,330,371,373,374,1,4,15,16,44,45,46,47,176,177,199,201,202,204,231,235,236,237,238,249,250,254,298,313,314,373,374,7,8,6,8,190,191,192,193,6,7,26,62,63,64,65,137,189,342,343,344,10,11,12,9,11,12,67,68,69,9,10,12,9,10,11,4,14,15,16,17,18,19,20,274,4,13,15,16,4,5,13,14,16,45,46,47,176,177,278,279,334,366,367,368,1,4,5,13,14,15,45,46,47,153,154,176,177,249,250,313,314,323,324,371,373,13,18,29,58,172,201,258,261,365,13,17,58,172,201,258,261,365,13,20,208,13,19,22,23,24,33,109,220,221,232,233,268,287,288,21,23,24,21,22,24,50,51,52,54,55,220,227,228,21,22,23,79,140,220,229,232,233,268,26,27,28,8,25,27,28,40,95,104,105,106,107,108,124,125,155,197,198,231,234,251,273,295,296,297,306,315,316,317,25,26,28,25,26,27,17,31,32,33,34,35,36,51,76,219,30,32,33,34,30,31,33,34,35,36,51,76,216,217,218,219,307,369,370,21,30,31,32,34,35,36,109,219,220,221,30,31,32,33,30,32,33,36,219,30,32,33,35,38,37,304,305,40,26,39,173,174,175,239,240,282,326,42,43,241,242,243,244,41,43,52,170,241,242,243,244,275,276,277,364,41,42,275,276,277,1,4,5,66,4,5,15,16,46,47,176,177,323,324,4,5,15,16,45,47,176,177,4,5,15,16,45,46,176,177,49,48,67,74,181,182,183,226,23,51,52,53,23,30,32,50,52,76,95,100,160,169,170,307,308,322,337,23,42,50,51,76,100,116,117,169,170,266,267,291,364,50,170,23,55,23,54,57,100,110,194,195,56,17,18,59,60,58,60,58,59,304,357,358,359,4,164,165,166,8,63,64,65,8,62,64,8,62,63,8,62,264,265,299,300,301,302,345,346,44,100,101,102,110,111,10,49,68,69,70,71,72,73,74,75,80,81,121,122,123,169,248,285,363,10,67,69,80,81,10,67,68,70,71,75,80,81,285,67,69,71,72,73,75,119,150,214,303,328,329,348,349,350,351,378,379,67,69,70,72,73,75,67,70,71,73,119,303,67,70,71,72,150,49,67,67,69,70,71,285,30,32,51,52,169,170,78,79,77,79,24,77,78,67,68,69,81,67,68,69,80,121,122,123,83,84,85,86,87,88,89,82,84,85,86,87,88,89,262,263,82,83,85,86,87,88,89,82,83,84,86,87,88,89,106,260,262,263,82,83,84,85,87,88,89,106,260,262,263,82,83,84,85,86,88,89,82,83,84,85,86,87,89,106,260,262,263,82,83,84,85,86,87,88,91,92,90,92,130,131,132,133,134,188,90,91,130,131,132,133,134,188,94,95,96,97,98,99,93,95,96,97,98,99,26,51,93,94,96,97,98,99,178,179,180,286,308,337,338,339,362,93,94,95,97,98,99,141,93,94,95,96,98,99,178,362,93,94,95,96,97,99,93,94,95,96,97,98,51,52,56,66,101,102,103,110,111,145,194,195,66,100,102,103,311,66,100,101,159,280,360,361,100,101,26,105,106,107,108,26,104,106,107,26,85,86,88,104,105,107,185,260,26,104,105,106,108,283,284,372,26,104,107,125,155,156,158,21,33,56,66,100,111,194,195,66,100,110,113,114,115,1,112,114,115,131,135,136,189,259,312,352,353,354,355,356,112,113,115,131,135,312,112,113,114,172,347,52,117,318,319,320,321,52,116,119,120,209,70,72,118,120,214,303,348,349,350,351,118,119,67,81,122,123,67,81,121,123,169,248,67,81,121,122,26,125,26,108,124,234,255,256,4,127,128,129,327,330,4,126,128,129,327,330,4,126,127,129,327,330,340,341,126,127,128,91,92,131,132,133,134,1,91,92,113,114,130,132,133,134,135,136,259,91,92,130,131,133,134,188,91,92,130,131,132,134,91,92,130,131,132,133,113,114,131,189,352,353,354,355,356,113,131,8,138,342,343,137,140,24,139,206,207,229,230,96,143,144,145,142,144,145,142,143,145,100,142,143,144,194,4,147,148,146,148,146,147,150,151,270,293,70,73,149,151,270,271,293,294,149,150,4,4,16,154,4,16,153,26,108,156,157,158,108,155,155,108,155,102,51,161,162,163,322,160,162,160,161,163,160,162,4,61,165,166,4,61,164,166,4,61,164,165,168,169,170,167,169,170,205,51,52,67,76,122,167,168,170,205,248,289,290,291,292,42,51,52,53,76,167,168,169,266,267,336,364,172,17,18,115,171,325,347,40,174,175,40,173,175,40,173,174,282,4,5,15,16,45,46,47,177,4,5,15,16,45,46,47,176,95,97,179,180,95,178,95,178,49,182,183,49,181,183,49,181,182,226,185,186,187,309,310,106,184,186,187,309,310,184,185,187,309,310,184,185,186,91,92,132,8,113,135,7,191,192,193,7,190,7,190,193,7,190,192,56,100,110,145,195,196,56,100,110,194,194,26,26,251,5,200,201,202,203,204,258,199,201,202,5,17,18,199,200,202,203,204,245,252,253,254,258,298,5,199,200,201,203,204,258,199,201,202,5,199,201,202,245,298,168,169,140,207,140,206,375,376,377,19,118,211,212,213,214,215,210,212,213,214,215,210,211,213,214,215,222,223,224,225,210,211,212,214,215,70,119,210,211,212,213,215,303,348,349,350,351,210,211,212,213,214,32,217,218,32,216,218,32,216,217,30,32,33,35,21,23,24,33,221,21,33,220,212,223,224,225,212,222,224,225,212,222,223,225,212,222,223,224,49,183,23,228,23,227,24,140,140,5,26,232,233,234,235,236,237,238,239,240,246,257,297,21,24,231,233,268,21,24,231,232,268,26,125,231,5,231,5,231,237,238,239,240,245,246,247,257,5,231,236,238,5,231,236,237,40,231,236,240,246,257,326,40,231,236,239,246,257,326,41,42,242,243,244,41,42,241,243,244,41,42,241,242,244,41,42,241,242,243,201,204,236,246,247,298,231,236,239,240,245,247,257,236,245,246,67,122,169,4,5,16,1,4,5,16,313,314,26,198,201,253,201,252,5,201,125,256,125,255,231,236,239,240,246,17,18,199,201,202,1,113,131,85,86,88,106,17,18,83,85,86,88,263,83,85,86,88,262,65,265,65,264,299,300,301,302,52,170,267,52,170,266,21,24,232,233,270,271,272,149,150,269,271,272,293,294,150,269,270,294,269,270,26,4,13,42,43,276,277,42,43,275,277,42,43,275,276,15,279,15,278,102,281,360,361,280,40,175,107,284,107,283,67,69,75,95,21,288,21,287,169,290,169,289,291,292,52,169,290,169,290,149,150,270,150,270,271,26,296,26,295,26,231,5,201,204,245,65,265,300,301,302,65,265,299,301,65,265,299,300,65,265,299,70,72,119,214,328,329,348,349,350,351,378,379,38,60,305,357,358,359,38,304,26,32,51,51,95,337,184,185,186,310,184,185,186,309,101,113,114,4,5,16,250,314,4,5,16,250,313,26,316,317,26,315,317,26,315,316,116,319,320,321,116,318,320,321,116,318,319,321,116,318,319,320,51,160,4,16,45,324,4,16,45,323,172,40,239,240,126,127,128,70,303,329,70,303,328,4,126,127,128,332,333,334,335,331,333,334,335,331,332,334,335,15,331,332,333,335,366,367,368,331,332,333,334,170,51,95,308,95,339,95,338,128,341,128,340,8,137,343,8,137,342,8,65,346,65,345,115,172,70,119,214,303,349,350,351,70,119,214,303,348,350,351,70,119,214,303,348,349,351,70,119,214,303,348,349,350,113,135,353,354,355,356,113,135,352,354,355,356,113,135,352,353,355,356,113,135,352,353,354,356,113,135,352,353,354,355,60,304,358,359,60,304,357,359,60,304,357,358,102,280,361,102,280,360,95,97,67,42,52,170,17,18,15,334,367,368,15,334,366,368,15,334,366,367,32,370,32,369,4,16,107,4,5,16,374,4,5,373,207,376,377,207,375,377,207,375,376,70,303,379,70,303,378],
                   [1,1,1,1,1,1,1,1,1,1,2,2,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,10,10,10,10,10,10,11,11,11,12,12,12,13,13,13,13,13,13,13,13,13,14,14,14,14,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,19,19,19,20,20,21,21,21,21,21,21,21,21,21,21,21,21,22,22,22,23,23,23,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,25,25,25,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,26,27,27,27,28,28,28,29,30,30,30,30,30,30,30,30,30,31,31,31,31,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,33,33,33,33,33,33,33,33,33,33,33,34,34,34,34,35,35,35,35,35,36,36,36,36,37,38,38,38,39,40,40,40,40,40,40,40,40,40,41,41,41,41,41,41,42,42,42,42,42,42,42,42,42,42,42,42,43,43,43,43,43,44,44,44,44,45,45,45,45,45,45,45,45,45,45,46,46,46,46,46,46,46,46,47,47,47,47,47,47,47,47,48,49,49,49,49,49,49,49,50,50,50,50,51,51,51,51,51,51,51,51,51,51,51,51,51,51,51,52,52,52,52,52,52,52,52,52,52,52,52,52,52,53,53,54,54,55,55,56,56,56,56,56,57,58,58,58,58,59,59,60,60,60,60,60,60,61,61,61,61,62,62,62,62,63,63,63,64,64,64,65,65,65,65,65,65,65,65,65,65,66,66,66,66,66,66,67,67,67,67,67,67,67,67,67,67,67,67,67,67,67,67,67,67,67,68,68,68,68,68,69,69,69,69,69,69,69,69,69,70,70,70,70,70,70,70,70,70,70,70,70,70,70,70,70,70,70,71,71,71,71,71,71,72,72,72,72,72,72,73,73,73,73,73,74,74,75,75,75,75,75,76,76,76,76,76,76,77,77,78,78,79,79,79,80,80,80,80,81,81,81,81,81,81,81,82,82,82,82,82,82,82,83,83,83,83,83,83,83,83,83,84,84,84,84,84,84,84,85,85,85,85,85,85,85,85,85,85,85,86,86,86,86,86,86,86,86,86,86,86,87,87,87,87,87,87,87,88,88,88,88,88,88,88,88,88,88,88,89,89,89,89,89,89,89,90,90,91,91,91,91,91,91,91,91,92,92,92,92,92,92,92,92,93,93,93,93,93,93,94,94,94,94,94,94,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,95,96,96,96,96,96,96,96,97,97,97,97,97,97,97,97,98,98,98,98,98,98,99,99,99,99,99,99,100,100,100,100,100,100,100,100,100,100,100,100,101,101,101,101,101,102,102,102,102,102,102,102,103,103,104,104,104,104,104,105,105,105,105,106,106,106,106,106,106,106,106,106,107,107,107,107,107,107,107,107,108,108,108,108,108,108,108,109,109,110,110,110,110,110,110,111,111,111,112,112,112,113,113,113,113,113,113,113,113,113,113,113,113,113,113,113,114,114,114,114,114,114,115,115,115,115,115,116,116,116,116,116,116,117,117,118,118,118,119,119,119,119,119,119,119,119,119,119,120,120,121,121,121,121,122,122,122,122,122,122,123,123,123,123,124,124,125,125,125,125,125,125,126,126,126,126,126,126,127,127,127,127,127,127,128,128,128,128,128,128,128,128,129,129,129,130,130,130,130,130,130,131,131,131,131,131,131,131,131,131,131,131,131,132,132,132,132,132,132,132,133,133,133,133,133,133,134,134,134,134,134,134,135,135,135,135,135,135,135,135,135,136,136,137,137,137,137,138,139,140,140,140,140,140,140,141,142,142,142,143,143,143,144,144,144,145,145,145,145,145,146,146,146,147,147,148,148,149,149,149,149,150,150,150,150,150,150,150,150,151,151,152,153,153,153,154,154,154,155,155,155,155,155,156,156,157,158,158,159,160,160,160,160,160,161,161,162,162,162,163,163,164,164,164,164,165,165,165,165,166,166,166,166,167,167,167,168,168,168,168,169,169,169,169,169,169,169,169,169,169,169,169,169,169,170,170,170,170,170,170,170,170,170,170,170,170,171,172,172,172,172,172,172,173,173,173,174,174,174,175,175,175,175,176,176,176,176,176,176,176,176,177,177,177,177,177,177,177,177,178,178,178,178,179,179,180,180,181,181,181,182,182,182,183,183,183,183,184,184,184,184,184,185,185,185,185,185,185,186,186,186,186,186,187,187,187,188,188,188,189,189,189,190,190,190,190,191,191,192,192,192,193,193,193,194,194,194,194,194,194,195,195,195,195,196,197,198,198,199,199,199,199,199,199,199,200,200,200,201,201,201,201,201,201,201,201,201,201,201,201,201,201,202,202,202,202,202,202,202,203,203,203,204,204,204,204,204,204,205,205,206,206,207,207,207,207,207,208,209,210,210,210,210,210,211,211,211,211,211,212,212,212,212,212,212,212,212,212,213,213,213,213,213,214,214,214,214,214,214,214,214,214,214,214,214,215,215,215,215,215,216,216,216,217,217,217,218,218,218,219,219,219,219,220,220,220,220,220,221,221,221,222,222,222,222,223,223,223,223,224,224,224,224,225,225,225,225,226,226,227,227,228,228,229,229,230,231,231,231,231,231,231,231,231,231,231,231,231,231,231,232,232,232,232,232,233,233,233,233,233,234,234,234,235,235,236,236,236,236,236,236,236,236,236,236,237,237,237,237,238,238,238,238,239,239,239,239,239,239,239,240,240,240,240,240,240,240,241,241,241,241,241,242,242,242,242,242,243,243,243,243,243,244,244,244,244,244,245,245,245,245,245,245,246,246,246,246,246,246,246,247,247,247,248,248,248,249,249,249,250,250,250,250,250,250,251,251,252,252,253,253,254,254,255,255,256,256,257,257,257,257,257,258,258,258,258,258,259,259,259,260,260,260,260,261,261,262,262,262,262,262,263,263,263,263,263,264,264,265,265,265,265,265,265,266,266,266,267,267,267,268,268,268,268,269,269,269,270,270,270,270,270,270,270,271,271,271,271,272,272,273,274,274,275,275,275,275,276,276,276,276,277,277,277,277,278,278,279,279,280,280,280,280,281,282,282,283,283,284,284,285,285,285,286,287,287,288,288,289,289,290,290,290,290,291,291,291,292,292,293,293,293,294,294,294,295,295,296,296,297,297,298,298,298,298,299,299,299,299,299,300,300,300,300,301,301,301,301,302,302,302,303,303,303,303,303,303,303,303,303,303,303,303,304,304,304,304,304,304,305,305,306,307,307,308,308,308,309,309,309,309,310,310,310,310,311,312,312,313,313,313,313,313,314,314,314,314,314,315,315,315,316,316,316,317,317,317,318,318,318,318,319,319,319,319,320,320,320,320,321,321,321,321,322,322,323,323,323,323,324,324,324,324,325,326,326,326,327,327,327,328,328,328,329,329,329,330,330,330,330,331,331,331,331,332,332,332,332,333,333,333,333,334,334,334,334,334,334,334,334,335,335,335,335,336,337,337,337,338,338,339,339,340,340,341,341,342,342,342,343,343,343,344,345,345,346,346,347,347,348,348,348,348,348,348,348,349,349,349,349,349,349,349,350,350,350,350,350,350,350,351,351,351,351,351,351,351,352,352,352,352,352,352,353,353,353,353,353,353,354,354,354,354,354,354,355,355,355,355,355,355,356,356,356,356,356,356,357,357,357,357,358,358,358,358,359,359,359,359,360,360,360,361,361,361,362,362,363,364,364,364,365,365,366,366,366,366,367,367,367,367,368,368,368,368,369,369,370,370,371,371,372,373,373,373,373,374,374,374,375,375,375,376,376,376,377,377,377,378,378,378,379,379,379],
                   1., 379, 379)
        v,lam2 = fiedler_vector(A)
        @test abs(lam2 - 3.026826881103339417e-03) <= dtol # result from LAPACK graph_eigs
        @test abs(v[1] - 1.878339361656544346e-02) <= dtol # result from Matlab
        # check inverse participation ratio score from graph_eigs
        @test abs.(sum(abs.(v).^4)/(sum(abs.(v).^2)^2) - 6.761596909820281540e-03) <= dtol

        n = 25
        A = sparse(1:n-1,2:n,1.,n,n)
        A = A + A'
        elam2 = 2*sin(pi/2*1/(n-1.))^2 # exact lam2
        v,lam2 = fiedler_vector(A)
        @show elam2
        @show lam2
        @test abs(lam2 - elam2) <= dtol


        n = 500
        A = sparse(1:n-1,2:n,1.,n,n)
        A = A + A'
        elam2 = 2*sin(pi/2*1/(n-1.))^2 # exact lam2
        v,lam2 = fiedler_vector(A;nev=6)
        @show elam2
        @show lam2
        @test abs(lam2 - elam2) <= dtol

        @test length(bestset(sweepcut(A,v))) == 250
    end
    @testset "Fiedler partition" begin
        # Make sure that the Fiedler partition will run properly on the largest
        # connected component.  The following network is the in-recip weighted motif
        # adjacency matrix for the Florida Bay food web.
        W = sparse([24,25,26,30,32,35,36,38,39,40,41,45,48,124,41,44,45,49,124,41,44,45,49,124,41,44,45,49,124,91,124,30,41,44,45,49,91,124,16,17,18,19,20,21,23,27,123,15,123,15,123,15,123,15,123,15,123,15,123,123,126,15,123,8,124,8,124,8,96,100,124,15,123,30,124,8,14,29,31,42,124,30,34,36,44,49,50,51,61,124,8,34,61,124,31,32,61,8,96,100,124,8,31,37,42,96,100,124,36,49,96,100,124,8,96,100,124,8,96,100,124,8,96,100,124,8,9,10,11,14,96,100,124,30,36,91,96,100,124,60,62,66,96,99,100,9,10,11,14,31,60,62,96,100,124,8,9,10,11,14,60,62,96,100,124,8,60,62,124,9,10,11,14,31,37,60,62,96,100,124,31,60,62,124,31,60,62,124,66,99,66,99,60,62,66,99,43,44,45,48,49,50,51,59,62,68,94,95,100,31,32,34,43,44,45,48,49,50,51,59,60,68,94,95,100,96,100,96,100,66,99,43,57,58,59,65,68,69,72,99,60,62,66,99,66,99,66,99,13,14,42,124,96,100,60,62,60,62,26,35,36,37,38,39,40,41,42,43,44,45,49,63,64,93,100,43,57,58,59,65,66,68,69,72,26,35,36,37,38,39,40,41,42,43,44,45,49,60,62,63,64,93,96,15,16,17,18,19,20,21,22,23,27,126,8,9,10,11,13,14,24,25,26,29,30,31,32,35,36,37,38,39,40,41,42,44,45,48,49,50,51,91,22,123],
        [8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11,13,13,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,26,26,27,27,29,29,30,30,30,30,30,30,31,31,31,31,31,31,31,31,31,32,32,32,32,34,34,34,35,35,35,35,36,36,36,36,36,36,36,37,37,37,37,37,38,38,38,38,39,39,39,39,40,40,40,40,41,41,41,41,41,41,41,41,42,42,42,42,42,42,43,43,43,43,43,43,44,44,44,44,44,44,44,44,44,44,45,45,45,45,45,45,45,45,45,45,48,48,48,48,49,49,49,49,49,49,49,49,49,49,49,50,50,50,50,51,51,51,51,57,57,58,58,59,59,59,59,60,60,60,60,60,60,60,60,60,60,60,60,60,61,61,61,62,62,62,62,62,62,62,62,62,62,62,62,62,63,63,64,64,65,65,66,66,66,66,66,66,66,66,66,68,68,68,68,69,69,72,72,91,91,91,91,93,93,94,94,95,95,96,96,96,96,96,96,96,96,96,96,96,96,96,96,96,96,96,99,99,99,99,99,99,99,99,99,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,123,123,123,123,123,123,123,123,123,123,123,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,124,126,126],
                   [1,1,1,1,1,1,1,1,1,1,1,1,1,13,1,1,1,1,4,1,1,1,1,4,1,1,1,1,4,1,1,1,1,1,1,1,1,6,1,1,1,1,1,1,1,1,8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,5,1,1,1,1,1,1,1,1,6,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,4,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,5,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,5,1,1,1,1,1,1,1,1,1,5,1,1,1,1,1,1,1,1,1,1,1,1,1,1,6,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,12,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,12,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,8,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,16,1,1,1,1,1,8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,16,8,1,1,1,1,1,1,1,1,1,1,13,4,4,4,1,6,1,1,1,1,5,6,1,1,4,2,1,1,1,5,3,5,5,1,6,1,1,3,1,1])

        sc = spectral_cut(W,true,true)
        @test length(sc.set) == 9
        @test length(intersect([57,58,59,65,66,68,69,72,99], sc.set)) == 9
    end
end
