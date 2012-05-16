# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "right_aws"
  s.version = "3.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["RightScale, Inc."]
  s.date = "2012-04-10"
  s.description = "== DESCRIPTION:\n\nThe RightScale AWS gems have been designed to provide a robust, fast, and secure interface to Amazon EC2, EBS, S3, SQS, SDB, and CloudFront.\nThese gems have been used in production by RightScale since late 2006 and are being maintained to track enhancements made by Amazon.\nThe RightScale AWS gems comprise:\n\n- RightAws::Ec2 -- interface to Amazon EC2 (Elastic Compute Cloud) and the\n  associated EBS (Elastic Block Store)\n- RightAws::S3 and RightAws::S3Interface -- interface to Amazon S3 (Simple Storage Service)\n- RightAws::Sqs and RightAws::SqsInterface -- interface to first-generation Amazon SQS (Simple Queue Service) (API version 2007-05-01)\n- RightAws::SqsGen2 and RightAws::SqsGen2Interface -- interface to second-generation Amazon SQS (Simple Queue Service) (API version 2008-01-01)\n- RightAws::SdbInterface and RightAws::ActiveSdb -- interface to Amazon SDB (SimpleDB)\n- RightAws::AcfInterface -- interface to Amazon CloudFront, a content distribution service\n\n== FEATURES:\n\n- Full programmmatic access to EC2, EBS, S3, SQS, SDB, and CloudFront.\n- Complete error handling: all operations check for errors and report complete\n  error information by raising an AwsError.\n- Persistent HTTP connections with robust network-level retry layer using\n  RightHttpConnection).  This includes socket timeouts and retries.\n- Robust HTTP-level retry layer.  Certain (user-adjustable) HTTP errors returned\n  by Amazon's services are classified as temporary errors.\n  These errors are automaticallly retried using exponentially increasing intervals.\n  The number of retries is user-configurable.\n- Fast REXML-based parsing of responses (as fast as a pure Ruby solution allows).\n- Uses libxml (if available) for faster response parsing.\n- Support for large S3 list operations.  Buckets and key subfolders containing\n  many (> 1000) keys are listed in entirety.  Operations based on list (like\n  bucket clear) work on arbitrary numbers of keys.\n- Support for streaming GETs from S3, and streaming PUTs to S3 if the data source is a file.\n- Support for single-threaded usage, multithreaded usage, as well as usage with multiple\n  AWS accounts.\n- Support for both first- and second-generation SQS (API versions 2007-05-01\n  and 2008-01-01).  These versions of SQS are not compatible.\n- Support for signature versions 0 and 1 on SQS, SDB, and EC2.\n- Interoperability with any cloud running Eucalyptus (http://eucalyptus.cs.ucsb.edu)\n- Test suite (requires AWS account to do \"live\" testing).\n"
  s.email = "support@rightscale.com"
  s.extra_rdoc_files = ["README.txt"]
  s.files = ["README.txt"]
  s.rdoc_options = ["--main", "README.txt", "--title", ""]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.requirements = ["libxml-ruby >= 0.5.2.0 is encouraged"]
  s.rubyforge_project = "rightaws"
  s.rubygems_version = "1.8.11"
  s.summary = "Interface classes for the Amazon EC2, SQS, and S3 Web Services"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<right_http_connection>, [">= 1.2.5"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<right_http_connection>, [">= 1.2.5"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<right_http_connection>, [">= 1.2.5"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end
